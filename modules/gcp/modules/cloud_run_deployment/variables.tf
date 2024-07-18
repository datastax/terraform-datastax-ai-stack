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
    domain = optional(string)
    containers = optional(object({
      cpu           = optional(string)
      memory        = optional(string)
      min_instances = optional(number)
      max_instances = optional(number)
    }))
  })
}

variable "infrastructure" {
  type = object({
    project_id     = string
    location       = string
    cloud_provider = string
  })
}
