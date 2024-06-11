variable "project_config" {
  type = object({
    project_id      = optional(string)
    create_project = optional(object({
      name            = optional(string)
      org_id          = optional(string)
      billing_account = string
    }))
  })
}

variable "cloud_run_config" {
  type = object({
    location = optional(string)
  })
}

variable "domain_config" {
  type = object({
    auto_cloud_dns_setup = bool
    managed_zones        = optional(map(object({
      dns_name  = optional(string)
      zone_name = optional(string)
    })))
  })
}

variable "components" {
  type = map(object({
    name         = string
    domain       = optional(string)
    service_name = string
  }))
}
