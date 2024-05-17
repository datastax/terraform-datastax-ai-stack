variable "project_config" {
  type = object({
    project_id      = optional(string)
    project_options = optional(object({
      name            = optional(string)
      org_id          = optional(string)
      billing_account = string
    }))
  })
  nullable = false

  validation {
    condition     = var.project_config.project_id != null && var.project_config.project_options == null || var.project_config.project_id == null && var.project_config.project_options != null
    error_message = "Either project_id or project_options must be set"
  }
}

variable "cloud_run_config" {
  type = object({
    location = optional(string)
  })
  default  = null
}

variable "domain_config" {
  type = object({
    auto_cloud_dns_setup = bool
    managed_zones        = optional(map(object({
      dns_name  = optional(string)
      zone_name = optional(string)
    })))
  })
  nullable = false

  default = {
    auto_cloud_dns_setup = false
  }

  validation {
    condition     = !var.domain_config.auto_cloud_dns_setup || var.domain_config.managed_zones != null
    error_message = "If auto_cloud_dns_setup is true, managed_zones must be set"
  }

  validation {
    condition     = var.domain_config.auto_cloud_dns_setup || var.domain_config.managed_zones == null
    error_message = "If auto_cloud_dns_setup is false, managed_zones must not be set"
  }

  validation {
    condition = var.domain_config.managed_zones == null || alltrue([
      for component, zone in coalesce(var.domain_config.managed_zones, {}) :
      (length(compact([zone.dns_name, zone.zone_name])) == 1)
    ])
    error_message = "If managed_zones is set, (exactly) one of either dns_name or zone_name must be set"
  }
}

variable "assistants" {
  type = object({
    domain = optional(string)
    db     = optional(object({
      regions             = set(string)
      deletion_protection = optional(bool)
      cloud_provider      = optional(string)
    }))
    containers = optional(object({
      cpu           = optional(number)
      memory        = optional(number)
      min_instances = optional(number)
      max_instances = optional(number)
    }))
  })
  default = null
}

variable "langflow" {
  type = object({
    domain     = optional(string)
    db_url     = optional(string)
    containers = optional(object({
      cpu           = optional(number)
      memory        = optional(number)
      min_instances = optional(number)
      max_instances = optional(number)
    }))
  })
  default = null
}

variable "vector_dbs" {
  type = list(object({
    name                = string
    regions             = set(string)
    keyspace            = optional(string)
    cloud_provider      = optional(string)
    deletion_protection = optional(bool)
  }))
  nullable = false
  default  = []
}
