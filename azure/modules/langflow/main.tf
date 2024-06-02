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

output "fqdn" {
  value = module.container_app_deployment.fqdn
}

module "container_app_deployment" {
  source         = "../container_app_deployment"
  container_info = local.container_info
  config         = var.config
  infrastructure = var.infrastructure
}
