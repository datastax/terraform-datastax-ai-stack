variable "container_info" {
  type = object({
    name  = string
    image = string
    port  = number
    env   = map(string)
    cmd   = optional(list(string))
  })
}

variable "config" {
  type = object({
    domain      = optional(string)
    containers  = optional(object({
      cpu           = optional(number)
      memory        = optional(number)
      min_instances = optional(number)
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
