variable "domain_config" {
  type = object({
    auto_route53_setup = optional(bool)
    hosted_zones       = optional(map(object({
      zone_id   = optional(string)
      zone_name = optional(string)
    })))
    acm_cert_arn  = optional(string)
  })
}

variable "alb_config" {
  type = object({
    vpc_id          = string
    public_subnets  = list(string)
    private_subnets = list(string)
    security_groups = list(string)
  })
  nullable = true
}

variable "fargate_config" {
  type = optional(object({
    capacity_provider_weights = optional(object({
      default_base   = number
      default_weight = number
      spot_base      = number
      spot_weight    = number
    }))
  }))
  nullable = true
}

variable "components" {
  type = list(object({
    name        = string
    name_prefix = string
    port        = number
    domain      = optional(string)
  }))
}
