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

# validation {
#   condition     = try(!(var.domain_config.auto_route53_setup == false && var.domain_config.acm_cert_arn == null), true)
#   error_message = "must provide an acm_cert_arn if auto_route53_setup isn't true"
# }

locals {
  _custom_domain_present = length([for config in local.components : 1 if config["domain"] != null]) > 0

  check_acm_cert_present_if_necessary = (local._custom_domain_present && try(!var.domain_config.auto_route53_setup && var.domain_config.acm_cert_arn == null, false)
    ? tobool("Must provide a domain_config.acm_cert_arn if domain_config.auto_route53_setup isn't true, and a custom domain is used")
    : true
  )
}

locals {
  components_used = length(local.components) > 0
}

locals {
  aws_infra_checks_pass = alltrue([
    local.check_domain_config_set_if_necessary,
    local.check_acm_cert_present_if_necessary,
    local.components_used,
  ])
}
