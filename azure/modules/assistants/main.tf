module "assistants_api_db" {
  source         = "../astra_db"
  cloud_provider = var.infrastructure.cloud_provider

  config = {
    name                = "assistant_api_db"
    keyspace            = "assistant_api"
    regions             = var.config.db.regions
    deletion_protection = try(coalesce(var.config.db.deletion_protection), null)
    cloud_provider      = try(coalesce(var.config.db.cloud_provider), null)
  }
}

locals {
  container_info = {
    name        = "astra-assistants"
    image       = "datastax/astra-assistants:v0.1.20"
    port        = 8000
    entrypoint  = ["poetry", "run", "uvicorn", "impl.main:app", "--host", "0.0.0.0", "--port", "8000"]
    health_path = "/v1/health"
    env         = var.config.env
  }
}

output "container_info" {
  value = local.container_info
}

output "fqdn" {
  value = module.container_app_deployment.fqdn
}

output "id" {
  value = module.container_app_deployment.id
}

output "domain_verification_id" {
  value = module.container_app_deployment.domain_verification_id
}

module "container_app_deployment" {
  source         = "../container_app_deployment"
  container_info = local.container_info
  config         = var.config
  infrastructure = var.infrastructure
}
