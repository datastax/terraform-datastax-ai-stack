variable "config" {
  type = object({
    domain     = optional(string)
    db_url     = optional(string)
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
