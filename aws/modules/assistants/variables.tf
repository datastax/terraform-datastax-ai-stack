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
    target_group_arn = string
    security_groups  = set(string)
    subnets          = set(string)
  })
}

variable "cloud_provider" {
  type = string
}
