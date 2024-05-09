variable "container_info" {
  type = object({
    name        = string
    image       = string
    port        = number
    health_path = string
  })
}

variable "config" {
  type = object({
    containers = optional(object({
      cpu           = optional(number)
      memory        = optional(number)
      desired_count = optional(number)
    }))
  })
}

variable "infrastructure" {
  type = object({
    cluster          = string
    target_group_arn = string
    security_groups  = set(string)
    subnets          = set(string)
  })
}

variable "force_desired_count" {
  type    = number
  default = null
}
