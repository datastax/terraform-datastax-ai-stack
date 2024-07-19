locals {
  container_info = {
    name        = "langflow"
    image       = "langflowai/langflow"
    port        = 7860
    health_path = "health"
  }

  using_managed_db = var.config.managed_db != null

  postgres_url = (local.using_managed_db
    ? "postgres://psqladmin:${random_string.admin_password[0].result}@${aws_db_instance.this[0].endpoint}/${aws_db_instance.this[0].db_name}"
    : null
  )

  merged_env = (try(var.config.containers.env["LANGFLOW_DATABASE_URL"], null) == null && local.postgres_url != null
    ? merge({ LANGFLOW_DATABASE_URL = local.postgres_url }, {
      for k, v in try(coalesce(var.config.containers.env), {}) : k => v if k != "LANGFLOW_DATABASE_URL"
    })
    : try(coalesce(var.config.containers.env), {})
  )

  merged_containers = merge(try(coalesce(var.config.containers), {}), { env = local.merged_env })
  merged_config     = merge(try(coalesce(var.config), {}), { containers = local.merged_containers })
}

output "container_info" {
  value = local.container_info
}

output "target_id" {
  value = module.ecs_deployment.target_id
}

module "ecs_deployment" {
  source           = "../ecs_deployment"
  infrastructure   = var.infrastructure
  config           = local.merged_config
  container_info   = local.container_info
  target_group_arn = var.target_group_arn
}

resource "random_string" "admin_password" {
  count = local.using_managed_db ? 1 : 0

  length           = 16
  override_special = "%*()-_=+[]{}?"
}

resource "aws_db_subnet_group" "db_subnet" {
  count = local.using_managed_db ? 1 : 0

  name       = "education"
  subnet_ids = var.infrastructure.private_subnets
}

resource "aws_db_subnet_group" "db_subnet2" {
  count = local.using_managed_db ? 1 : 0

  name       = "langflow_db_subnet"
  subnet_ids = var.infrastructure.public_subnets
}

resource "random_string" "random_id" {
  count = local.using_managed_db ? 1 : 0

  length  = 6
  special = false

  keepers = { time = timestamp() }
}

resource "aws_db_instance" "this" {
  count = local.using_managed_db ? 1 : 0

  identifier                = "langflow-managed-db"
  instance_class            = var.config.managed_db.instance_class
  allocated_storage         = try(coalesce(var.config.managed_db.initial_storage), 10)
  max_allocated_storage     = try(coalesce(var.config.managed_db.max_storage), 10)
  engine                    = "postgres"
  engine_version            = "16"
  username                  = "psqladmin"
  password                  = random_string.admin_password[0].result
  db_subnet_group_name      = aws_db_subnet_group.db_subnet[0].name
  vpc_security_group_ids    = var.infrastructure.security_groups
  deletion_protection       = var.config.managed_db.deletion_protection
  availability_zone         = var.config.managed_db.availability_zone
  final_snapshot_identifier = "langflow-managed-db-snap-${random_string.random_id[0].result}"
  db_name                   = "postgres"
  publicly_accessible       = true
}
