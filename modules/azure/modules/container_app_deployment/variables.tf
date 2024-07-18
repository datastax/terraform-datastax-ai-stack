variable "container_info" {
  type = object({
    name        = string
    image       = string
    port        = number
    env         = map(string)
    entrypoint  = optional(list(string))
    health_path = string
  })
}

variable "config" {
  type = object({
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
  })
}
