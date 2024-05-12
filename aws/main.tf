locals {
  cloud_provider = "aws"

  create_assistants = var.assistants != null
  create_langflow   = var.langflow != null

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

  alb_config     = var.alb_config
  domain_config  = var.domain_config
  fargate_config = var.fargate_config
  components     = local.components
}

module "assistants" {
  source = "./modules/assistants"
  count  = local.create_assistants ? 1 : 0

  cloud_provider = local.cloud_provider
  config         = var.assistants

  infrastructure = {
    cluster          = module.aws_infra.ecs_cluster_id
    target_group_arn = module.aws_infra.target_groups[module.assistants[0].container_info.name].arn
    security_groups  = module.aws_infra.security_groups
    subnets          = module.aws_infra.subnet_ids
  }
}

module "langflow" {
  source = "./modules/langflow"
  count  = local.create_langflow ? 1 : 0

  cloud_provider = local.cloud_provider
  config         = var.langflow

  infrastructure = {
    cluster          = module.aws_infra.ecs_cluster_id
    target_group_arn = module.aws_infra.target_groups[module.langflow[0].container_info.name].arn
    security_groups  = module.aws_infra.security_groups
    subnets          = module.aws_infra.subnet_ids
  }
}

module "vector_dbs" {
  source = "./modules/astra_db"

  for_each = {
    for db in var.vector_dbs : db.name => db
  }

  cloud_provider = local.cloud_provider
  config         = each.value
}
