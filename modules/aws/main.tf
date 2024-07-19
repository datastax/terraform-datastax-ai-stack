locals {
  create_assistants = var.assistants != null
  create_langflow   = var.langflow != null

  infrastructure = {
    cluster         = try(module.aws_infra[0].ecs_cluster_id, null)
    security_groups = try(module.aws_infra[0].security_groups, null)
    private_subnets = try(module.aws_infra[0].private_subnets, null)
    public_subnets  = try(module.aws_infra[0].public_subnets, null)
    cloud_provider  = "aws"
  }

  components = [
    for each in [
      (local.create_assistants ? {
        name        = module.assistants[0].container_info.name
        port        = module.assistants[0].container_info.port
        domain      = var.assistants.domain
        name_prefix = "assist"
      } : null),
      (local.create_langflow ? {
        name        = module.langflow[0].container_info.name
        port        = module.langflow[0].container_info.port
        domain      = var.langflow.domain
        name_prefix = "l-flow"
      } : null)
    ] : each if each != null
  ]
}

module "aws_infra" {
  source = "./modules/aws_infra"
  count  = local.aws_infra_checks_pass ? 1 : 0

  alb_config          = var.infrastructure
  domain_config       = var.domain_config
  components          = local.components
  deployment_defaults = var.deployment_defaults
}

module "assistants" {
  source = "./modules/assistants"
  count  = local.create_assistants ? 1 : 0

  infrastructure   = local.infrastructure
  target_group_arn = module.aws_infra[0].target_groups[module.assistants[0].container_info.name].arn

  config = merge(var.assistants, {
    deployment = merge(var.deployment_defaults, { for k, v in coalesce(var.assistants.deployment, {}) : k => v if v != null })
  })
}

module "langflow" {
  source = "./modules/langflow"
  count  = local.create_langflow ? 1 : 0

  infrastructure   = local.infrastructure
  target_group_arn = module.aws_infra[0].target_groups[module.langflow[0].container_info.name].arn

  config = merge(var.langflow, {
    deployment = merge(var.deployment_defaults, { for k, v in coalesce(var.langflow.deployment, {}) : k => v if v != null })
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
