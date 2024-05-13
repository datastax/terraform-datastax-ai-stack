variable "config" {
  type = object({
    db = object({
      regions             = set(string)
      deletion_protection = optional(bool)
      cloud_provider      = optional(string)
    })
    domain     = optional(string)
    containers = optional(object({
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
