variable "config" {
  type = object({
    db_url = optional(string)
    containers = optional(object({
      cpu    = optional(number)
      memory = optional(number)
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

