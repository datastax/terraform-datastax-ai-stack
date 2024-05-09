variable "container_info" {
  type = object({
    name  = string
    image = string
    port  = number
  })
}

variable "config" {
  type = object({
    domain           = optional(string)
    make_public      = optional(bool)
    container_limits = optional(object({
      cpu    = optional(number)
      memory = optional(number)
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
