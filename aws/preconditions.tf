check "check_domain_config_unset_if_necessary" {
  assert {
    condition     = local.components_used || var.domain_config == null
    error_message = "If no ECS-deployed components (langflow, assistants) are defined, domain_config won't do anything"
  }
}

locals {
  _domain_config_set = var.domain_config == null

  check_domain_config_set_if_necessary = ((local.components_used && local._domain_config_set)
    ? tobool("If any ECS-deployed components (langflow, assistants) are defined, domain_config is required to be set")
    : true
  )
}

locals {
  components_used = length(local.components) > 0
}

locals {
  aws_infra_checks_pass = alltrue([
    local.check_domain_config_set_if_necessary,
    local.components_used,
  ])
}
