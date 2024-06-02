variable "config" {
  type = object({
    env        = optional(map(string))
    containers = optional(object({
      cpu           = optional(number)
      memory        = optional(number)
      min_instances = optional(number)
      max_instances = optional(number)
    }))
  })
}

variable "infrastructure" {
  type = object({
    container_app_environment_id = string
    resource_group_name          = string
    cloud_provider               = string
  })
}
