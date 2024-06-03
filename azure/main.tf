locals {
  create_assistants = var.assistants != null
  create_langflow   = var.langflow != null

  infrastructure = {
    container_app_environment_id = module.azure_infra.container_app_environment_id
    resource_group_name          = module.azure_infra.resource_group_name
    resource_group_id            = module.azure_infra.resource_group_id
    cloud_provider               = "gcp"
  }

  components = [
    for each in [
      (local.create_assistants ? {
        name                   = "assistants"
        subdomain              = var.assistants.subdomain
        app_id                 = module.assistants[0].id
        domain_verification_id = module.assistants[0].domain_verification_id
        app_fqdn               = module.assistants[0].fqdn
      } : null),
      (local.create_langflow ? {
        name                   = "langflow"
        subdomain              = var.langflow.subdomain
        app_id                 = module.langflow[0].id
        domain_verification_id = module.langflow[0].domain_verification_id
        app_fqdn               = module.langflow[0].fqdn
      } : null)
    ] : each if each != null
  ]
}

module "azure_infra" {
  source = "./modules/azure_infra"

  domain_config         = var.domain_config
  resource_group_config = var.resource_group_config

  components = nonsensitive({
    for component in local.components : component["name"] => component
  })
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
