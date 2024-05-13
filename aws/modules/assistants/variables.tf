variable "config" {
  type = object({
    db = object({
      regions             = set(string)
      deletion_protection = optional(bool)
      cloud_provider      = optional(string)
    })
    containers = optional(object({
      cpu           = optional(number)
      memory        = optional(number)
      desired_count = optional(number)
    }))
  })
  nullable = true
}

variable "infrastructure" {
  type = object({
    cluster          = string
    security_groups  = set(string)
    subnets          = set(string)
    cloud_provider   = string
  })
}

variable "target_group_arn" {
  type = string
}
