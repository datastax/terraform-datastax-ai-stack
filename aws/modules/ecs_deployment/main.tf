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
  name = "ecs_execution_role"

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
        startPeriod = 60
      }
      environment = [
        { name = "ECS_ENABLE_CONTAINER_METADATA", value = "true" }
      ]
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

  desired_count = (var.force_desired_count != null
    ? var.force_desired_count
    : try(coalesce(var.config.containers.desired_count), 1))

  enable_execute_command = true

  lifecycle {
    ignore_changes = [desired_count]
  }

  load_balancer {
    container_name   = var.container_info.name
    container_port   = var.container_info.port
    target_group_arn = var.infrastructure.target_group_arn
  }

  network_configuration {
    security_groups = var.infrastructure.security_groups
    subnets         = var.infrastructure.subnets
  }
}
