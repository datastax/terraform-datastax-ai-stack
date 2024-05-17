output "target_id" {
  value = aws_ecs_service.this.id
}

data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "execute_command_policy" {
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name_prefix        = "ecs_execution_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_ecs_task_definition" "this" {
  container_definitions = jsonencode([
    {
      image        = var.container_info.image,
      name         = var.container_info.name,
      portMappings = [{ containerPort = var.container_info.port }],
      healthCheck = {
        command = [
          "CMD-SHELL", "curl -f http://localhost:${var.container_info.port}/${var.container_info.health_path} || exit 1"
        ]
        startPeriod = 120
      }
      environment = concat([
        { name = "ECS_ENABLE_CONTAINER_METADATA", value = "true" }
      ], [
        for key, value in var.container_info.env : {
          name  = key
          value = value
        }
      ])
      command = var.container_info.entrypoint
    }
  ])

  family                   = "${var.container_info.name}-tasks"
  cpu                      = try(coalesce(var.config.containers.cpu), 1024)
  memory                   = try(coalesce(var.config.containers.memory), 2048)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.ecs_execution_role.arn
}

resource "aws_ecs_service" "this" {
  cluster         = var.infrastructure.cluster
  task_definition = aws_ecs_task_definition.this.arn
  name            = var.container_info.name
  launch_type     = "FARGATE"
  desired_count   = try(var.config.containers.desired_count, 1)

  enable_execute_command = true

  load_balancer {
    container_name   = var.container_info.name
    container_port   = var.container_info.port
    target_group_arn = var.target_group_arn
  }

  network_configuration {
    security_groups = var.infrastructure.security_groups
    subnets         = var.infrastructure.subnets
  }
}

resource "aws_appautoscaling_target" "this" {
  min_capacity       = var.config.min_instances
  max_capacity       = var.config.max_instances
  resource_id        = "service/${var.infrastructure.cluster}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu_tracking" {
  name               = "${aws_ecs_service.this.name}-cpu-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 80

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    scale_out_cooldown  = 60
    scale_in_cooldown   = 60
  }
}

resource "aws_appautoscaling_policy" "mem_tracking" {
  name               = "${aws_ecs_service.this.name}-mem-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 80

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    scale_out_cooldown  = 60
    scale_in_cooldown   = 60
  }
}
