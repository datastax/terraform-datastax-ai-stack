variable "domain_config" {
  type = object({
    auto_route53_setup = optional(bool)
    hosted_zones       = optional(map(object({
      name = optional(string)
      id   = optional(string)
    })))
    auto_acm_cert = optional(bool)
    acm_cert_arn  = optional(string)
  })

  description = <<EOF
    domain_config is an object that contains the configuration for the domain and certificates.
    auto_route53_setup: If true, the module will create the hosted zones and route53 records for the domain.
    hosted_zones: A map of hosted zones to create. The key is the name of the hosted zone and the value is an object with the following fields:
      - name: The name of the hosted zone.
      - id: The id of the hosted zone. If not provided, the module will create a new hosted zone.
    auto_acm_cert: If true, the module will create a new ACM certificate for the domain.
    acm_cert_arn: The ARN of an existing ACM certificate to use for the domain. If not provided, the module will create a new ACM certificate.
    EOF
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
