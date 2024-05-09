locals {
  container_info = {
    name  = "langflow"
    image = "langflowai/langflow:latest"
    port  = 7860
    health_path = "health"
  }
}

output "container_info" {
  value = local.container_info
}

output "target_id" {
  value = module.ecs_deployment.target_id
}

module "ecs_deployment" {
  source              = "../ecs_deployment"
  infrastructure      = var.infrastructure
  config              = var.config
  container_info      = local.container_info
  force_desired_count = 1
}
