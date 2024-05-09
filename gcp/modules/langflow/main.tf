locals {
  container_info = {
    name  = "langflow"
    image = "langflowai/langflow:latest"
    port  = 7860
  }
}

output "container_info" {
  value = local.container_info
}

module "cloud_run_deployment" {
  source         = "../cloud_run_deployment"
  container_info = local.container_info
  config         = var.config
  infrastructure = var.infrastructure
}
