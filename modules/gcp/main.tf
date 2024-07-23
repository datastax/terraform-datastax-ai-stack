locals {
  create_assistants = var.assistants != null
  create_langflow   = var.langflow != null

  deployment_defaults = merge({ location = try(module.gcp_infra[0].location, null) }, { for k, v in var.deployment_defaults : k => v if v != null })

  infrastructure = {
    project_id     = try(module.gcp_infra[0].project_id, null)
    cloud_provider = "gcp"
  }

  components = [
    for each in [
      (local.create_assistants ? {
        name         = "assistants"
        service_name = module.assistants[0].service_name
        domain       = var.assistants.domain
      } : null),
      (local.create_langflow ? {
        name         = "langflow"
        service_name = module.langflow[0].service_name
        domain       = var.langflow.domain
      } : null)
    ] : each if each != null
  ]
}

module "gcp_infra" {
  source = "./modules/gcp_infra"
  count  = local.gcp_infra_checks_pass ? 1 : 0

  project_config      = var.project_config
  deployment_defaults = var.deployment_defaults
  domain_config       = var.domain_config

  components = {
    for component in local.components : component["name"] => component
  }
}

module "assistants" {
  source = "./modules/assistants"
  count  = local.create_assistants ? 1 : 0

  infrastructure = local.infrastructure

  config = merge(var.assistants, {
    deployment = merge(local.deployment_defaults, { for k, v in coalesce(var.assistants.deployment, {}) : k => v if v != null })
  })
}

module "langflow" {
  source = "./modules/langflow"
  count  = local.create_langflow ? 1 : 0

  infrastructure = local.infrastructure

  config = merge(var.langflow, {
    deployment = merge(local.deployment_defaults, { for k, v in coalesce(var.langflow.deployment, {}) : k => v if v != null })
  })
}

module "vector_dbs" {
  source = "./modules/astra_db"

  for_each = {
    for db in var.vector_dbs : db.name => db
  }

  cloud_provider = local.infrastructure.cloud_provider
  config         = each.value
}
