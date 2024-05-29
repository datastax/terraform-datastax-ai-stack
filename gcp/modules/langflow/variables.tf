variable "config" {
  type = object({
    domain     = optional(string)
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
    project_id     = string
    location       = string
    cloud_provider = string
  })
}
