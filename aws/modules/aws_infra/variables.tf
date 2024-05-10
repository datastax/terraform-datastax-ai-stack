variable "domain_config" {
  type = object({
    auto_route53_setup = optional(bool)
    hosted_zones       = map(object({
      name = optional(string)
      id   = optional(string)
    }))
    auto_acm_cert = optional(bool)
    acm_cert_arn  = optional(string)
  })
  nullable = true
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
  type = object({
    capacity_provider_weights = optional(object({
      default_base   = number
      default_weight = number
      spot_weight    = number
      spot_base      = number
    }))
  })
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
