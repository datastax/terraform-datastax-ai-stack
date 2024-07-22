variable "config" {
  type = object({
    containers = optional(object({
      env    = optional(map(string))
      cpu    = optional(number)
      memory = optional(string)
    }))
    deployment = optional(object({
      image_version = optional(string)
      min_instances = optional(number)
      max_instances = optional(number)
    }))
    astra_db = optional(object({
      regions             = optional(set(string))
      deletion_protection = optional(bool)
      cloud_provider      = optional(string)
    }))
  })
  nullable = false
}

variable "infrastructure" {
  type = object({
    container_app_environment_id = string
    resource_group_name          = string
    resource_group_id            = string
    cloud_provider               = string
  })
  nullable = false
}
