output "target_id" {
  value = aws_ecs_service.this.id
}

resource "aws_ecs_task_definition" "this" {
  container_definitions = jsonencode([
    {
      image        = var.container_info.image,
      name         = var.container_info.name,
      portMappings = [{ containerPort = var.container_info.port }],
      healthCheck = {
        command     = [
          "CMD-SHELL", "curl -f http://localhost:${var.container_info.port}/${var.container_info.health_path} || exit 1"
        ]
        startPeriod = 60
      }
    }
  ])

  family                   = "${var.container_info.name}-tasks"
  cpu                      = try(coalesce(var.config.containers.cpu), 1024)
  memory                   = try(coalesce(var.config.containers.memory), 2048)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
}

resource "aws_ecs_service" "this" {
  cluster         = var.infrastructure.cluster
  task_definition = aws_ecs_task_definition.this.arn
  name            = var.container_info.name
  launch_type     = "FARGATE"

  desired_count = (var.force_desired_count != null
    ? var.force_desired_count
    : try(coalesce(var.config.containers.desired_count), 1))

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
