variable "config" {
  type = object({
    domain = optional(string)
    containers = optional(object({
      env    = optional(map(string))
      cpu    = optional(number)
      memory = optional(number)
    }))
    deployment = optional(object({
      image_version = optional(string)
      min_instances = optional(number)
      max_instances = optional(number)
    }))
    managed_db = optional(object({
      regions             = optional(set(string))
      deletion_protection = optional(bool)
      cloud_provider      = optional(string)
    }))
  })
  nullable = false
}

variable "infrastructure" {
  type = object({
    cluster         = string
    security_groups = set(string)
    private_subnets = set(string)
    cloud_provider  = string
  })
  nullable = false
}

variable "target_group_arn" {
  type     = string
  nullable = false
}
