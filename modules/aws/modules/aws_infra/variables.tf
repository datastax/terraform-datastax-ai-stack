variable "domain_config" {
  type = object({
    auto_route53_setup = optional(bool)
    hosted_zones = optional(map(object({
      zone_id   = optional(string)
      zone_name = optional(string)
    })))
    acm_cert_arn = optional(string)
  })
}

variable "alb_config" {
  type = object({
    vpc_id          = string
    public_subnets  = list(string)
    private_subnets = list(string)
    security_groups = list(string)
  })
}

variable "components" {
  type = list(object({
    name        = string
    name_prefix = string
    port        = number
    domain      = optional(string)
  }))
}

variable "deployment_defaults" {
  type = object({
    vpc_availability_zones = optional(list(string))
    capacity_provider_weights = optional(object({
      default_base   = number
      default_weight = number
      spot_base      = number
      spot_weight    = number
    }))
  })
  nullable = false
  default  = {}
}
