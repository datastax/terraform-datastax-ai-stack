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
      location        = optional(string)
    }))
    managed_db = optional(object({
      regions             = optional(set(string))
      deletion_protection = optional(bool)
      cloud_provider      = optional(string)
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
