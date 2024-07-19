variable "container_info" {
  type = object({
    name        = string
    image       = string
    port        = number
    entrypoint  = optional(list(string))
    health_path = string
  })
  nullable = false
}

variable "config" {
  type = object({
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
  })
  nullable = false
}

variable "infrastructure" {
  type = object({
    cluster         = string
    security_groups = set(string)
    private_subnets = set(string)
  })
  nullable = false
}

variable "target_group_arn" {
  type     = string
  nullable = false
}
