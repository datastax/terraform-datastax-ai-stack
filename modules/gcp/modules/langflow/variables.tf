variable "config" {
  type = object({
    domain = optional(string)
    containers = optional(object({
      env    = optional(map(string))
      cpu    = optional(string)
      memory = optional(string)
    }))
    deployment = optional(object({
      image_version   = optional(string)
      min_instances   = optional(number)
      max_instances   = optional(number)
      service_account = optional(string)
      location        = string
    }))
    managed_db = optional(object({
      tier                = string
      region              = optional(string)
      deletion_protection = optional(bool)
      initial_storage     = optional(number)
      max_storage         = optional(number)
    }))
  })
  nullable = false
}

variable "infrastructure" {
  type = object({
    project_id     = string
    cloud_provider = string
  })
  nullable = false
}
