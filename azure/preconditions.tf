check "check_resource_group_config_and_domain_config_unset_if_necessary" {
  assert {
    condition     = local.components_used || (var.resource_group_config == null && var.domain_config == null)
    error_message = "If no Azure-deployed components (langflow, assistants) are defined, resource_group_config nor domain_config won't do anything"
  }
}

locals {
  _resource_group_config_and_domain_config_set = (var.resource_group_config == null || var.domain_config == null)

  check_resource_group_config_and_domain_config_set_if_necessary = ((local.components_used && local._resource_group_config_and_domain_config_set)
    ? tobool("If any Azure-deployed components (langflow, assistants) are defined, resource_group_config and domain_config are required to be set")
    : true
  )
}

locals {
  components_used = anytrue([
    local.create_langflow,
    local.create_assistants,
  ])
}

locals {
  azure_infra_checks_pass = alltrue([
    local.check_resource_group_config_and_domain_config_set_if_necessary,
    local.components_used,
  ])
}
