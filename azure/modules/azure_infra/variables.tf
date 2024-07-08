variable "resource_group_config" {
  type = object({
    resource_group_name = optional(string)
    create_resource_group = optional(object({
      name     = optional(string)
      location = optional(string)
    }))
  })
  nullable = false
}

variable "domain_config" {
  type = object({
    auto_azure_dns_setup = bool
    dns_zones = optional(map(object({
      dns_zone            = optional(string)
      resource_group_name = optional(string)
    })))
  })
}

variable "components" {
  type = map(object({
    name                   = string
    subdomain              = string
    app_id                 = string
    domain_verification_id = string
    app_fqdn               = string
  }))
}
