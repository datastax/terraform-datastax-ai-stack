locals {
  db_url_env = var.config.db_url != null ? {
    LANGFLOW_DATABASE_URL = var.config.db_url
  } : {}

  container_info = {
    name        = "langflow"
    image       = "langflowai/langflow:latest"
    port        = 7860
    health_path = "health"
    env         = merge(local.db_url_env)
  }
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
  config           = var.config
  container_info   = local.container_info
  target_group_arn = var.target_group_arn
}
