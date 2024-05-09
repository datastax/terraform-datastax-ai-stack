variable "aws_config" {
  type = object({
    auto_route53_dns_config = optional(bool)
    alb_config              = optional(object({
      vpc_id          = string
      public_subnets  = list(string)
      private_subnets = list(string)
      security_groups = list(string)
    }))
    fargate_config = optional(object({
      capacity_provider_weights = optional(object({
        default_base   = number
        default_weight = number
        spot_weight    = number
        spot_base      = number
      }))
    }))
  })
}

variable "components" {
  type = list(object({
    name        = string
    name_prefix = string
    port        = number
    domain      = object({
      name             = string
      hosted_zone_id   = optional(string)
      hosted_zone_name = optional(string)
    })
  }))
}
