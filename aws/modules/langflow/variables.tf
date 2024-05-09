variable "config" {
  type = object({
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
    target_group_arn = string
    security_groups  = set(string)
    subnets          = set(string)
  })
}

variable "cloud_provider" {
  type = string
}
