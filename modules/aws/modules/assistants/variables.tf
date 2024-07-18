variable "config" {
  type = object({
    version = optional(string)
    env     = optional(map(string))
    db = optional(object({
      regions             = optional(set(string))
      deletion_protection = optional(bool)
      cloud_provider      = optional(string)
    }))
    containers = optional(object({
      cpu           = optional(number)
      memory        = optional(number)
      min_instances = optional(number)
      max_instances = optional(number)
    }))
  })
  nullable = true
}

variable "infrastructure" {
  type = object({
    cluster         = string
    security_groups = set(string)
    subnets         = set(string)
    cloud_provider  = string
  })
}

variable "target_group_arn" {
  type = string
}
