variable "container_info" {
  type = object({
    service_name  = string
    image_name    = string
    port          = number
    entrypoint    = optional(list(string))
    health_path   = string
    csql_instance = optional(string)
  })
}

variable "using_managed_db" {
  type    = bool
  default = false
}

variable "config" {
  type = object({
    domain = optional(string)
    containers = optional(object({
      env    = optional(map(string))
      cpu    = optional(string)
      memory = optional(string)
    }))
    deployment = optional(object({
      image_version   = optional(string)
      min_instances   = optional(number)
      max_instances   = optional(number)
      service_account = optional(string)
      location        = string
    }))
  })
}

variable "infrastructure" {
  type = object({
    project_id     = string
    cloud_provider = string
  })
}
