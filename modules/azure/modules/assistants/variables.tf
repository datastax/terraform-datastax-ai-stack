variable "config" {
  type = object({
    version = optional(string)
    env     = optional(map(string))
    db = object({
      regions             = optional(set(string))
      deletion_protection = optional(bool)
      cloud_provider      = optional(string)
    })
    containers = optional(object({
      cpu           = optional(number)
      memory        = optional(string)
      min_instances = optional(number)
      max_instances = optional(number)
    }))
  })
}

variable "infrastructure" {
  type = object({
    container_app_environment_id = string
    resource_group_name          = string
    resource_group_id            = string
    cloud_provider               = string
  })
}
