locals {
  container_info = {
    name        = "langflow"
    image       = "langflowai/langflow:latest"
    port        = 7860
    env         = var.config.env
    health_path = "/health"
  }
}

output "container_info" {
  value = local.container_info
}

output "service_name" {
  value = module.cloud_run_deployment.service_name
}

module "cloud_run_deployment" {
  source         = "../cloud_run_deployment"
  container_info = local.container_info
  config         = var.config
  infrastructure = var.infrastructure
}
