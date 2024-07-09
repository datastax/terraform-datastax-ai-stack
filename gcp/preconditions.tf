check "check_project_config_and_domain_config_unset_if_necessary" {
  assert {
    condition     = local.components_used || (var.project_config == null && var.domain_config == null)
    error_message = "If no GCP-deployed components (langflow, assistants) are defined, project_config nor domain_config won't do anything"
  }
}

locals {
  _project_config_and_domain_config_set = (var.project_config == null || var.domain_config == null)

  check_project_config_and_domain_config_set_if_necessary = ((local.components_used && local._project_config_and_domain_config_set)
    ? tobool("If any GCP-deployed components (langflow, assistants) are defined, project_config and domain_config are required to be set")
    : true
  )
}

locals {
  _has_all_managed_zones = try(
    !var.domain_config.auto_cloud_dns_setup || alltrue([
      for component in local.components[*]["name"] : (try(
        var.domain_config.managed_zones[component],
        var.domain_config.managed_zones["default"],
        null
      ) != null)
    ]),
    true
  )

  check_domain_config_managed_zones = ((!local._has_all_managed_zones)
    ? tobool("If managed_zones is set, a managed zone must be provided for every component")
    : true
  )
}

locals {
  components_used = length(local.components) > 0
}

locals {
  gcp_infra_checks_pass = alltrue([
    local.check_project_config_and_domain_config_set_if_necessary,
    local.check_domain_config_managed_zones,
    local.components_used,
  ])
}
