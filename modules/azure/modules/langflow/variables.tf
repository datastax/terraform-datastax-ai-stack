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
    managed_db = optional(object({
      sku_name    = string
      location    = optional(string)
      max_storage = optional(number)
    }))
  })
  nullable = false
}

variable "infrastructure" {
  type = object({
    container_app_environment_id = string
    resource_group_name          = string
    resource_group_id            = string
    resource_group_location      = string
    cloud_provider               = string
  })
  nullable = false
}
