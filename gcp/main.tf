data "google_cloud_run_locations" "available" {
  project = local.project_id
}

module "gcp_infra" {
  source     = "./modules/gcp_infra"
  count      = var.gcp_config.project_options != null ? 1 : 0
  gcp_config = var.gcp_config
}

locals {
  create_assistants = var.assistants != null
  create_langflow   = var.langflow != null

  project_id = try(coalesce(var.gcp_config.project_id), module.gcp_infra[0].project_id)
  location   = try(coalesce(var.gcp_config.cloud_run_location), data.google_cloud_run_locations.available.locations[0])

  infrastructure = {
    project_id     = local.project_id
    location       = local.location
    cloud_provider = "gcp"
  }
}

output "project_id" {
  value = local.infrastructure.project_id
}

module "assistants" {
  source         = "./modules/assistants"
  count          = local.create_assistants ? 1 : 0
  config         = var.assistants
  infrastructure = local.infrastructure
}

module "langflow" {
  source         = "./modules/langflow"
  count          = local.create_langflow ? 1 : 0
  config         = var.langflow
  infrastructure = local.infrastructure
}

module "vector_dbs" {
  source = "./modules/astra_db"

  for_each = {
    for db in var.vector_dbs : db.name => db
  }

  cloud_provider = local.infrastructure.cloud_provider
  config         = each.value
}
