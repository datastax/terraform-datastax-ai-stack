variable "container_info" {
  type = object({
    name        = string
    image       = string
    port        = number
    entrypoint  = optional(list(string))
    health_path = string
  })
  nullable = false
}

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
  })
  nullable = false
}

variable "infrastructure" {
  type = object({
    container_app_environment_id = string
    resource_group_name          = string
    resource_group_id            = string
  })
  nullable = false
}
