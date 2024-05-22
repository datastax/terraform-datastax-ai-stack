variable "domain_config" {
  type = object({
    auto_route53_setup = bool
    hosted_zones       = optional(map(object({
      zone_name = optional(string)
      zone_id   = optional(string)
    })))
    auto_acm_cert = optional(bool)
    acm_cert_arn  = optional(string)
  })
  nullable = false

  validation {
    condition     = !(var.domain_config.auto_acm_cert == true && var.domain_config.auto_route53_setup != true)
    error_message = "auto_acm_cert requires auto_route53_setup to be true"
  }

  validation {
    condition     = !(var.domain_config.auto_route53_setup == true && length(var.domain_config.hosted_zones) == 0)
    error_message = "auto_route53_setup requires hosted_zones to be provided"
  }

  validation {
    condition     = !(var.domain_config.auto_acm_cert == true && var.domain_config.acm_cert_arn != null)
    error_message = "cannot provide a cert if auto_acm_cert is true"
  }

  validation {
    condition     = !(var.domain_config.auto_acm_cert != true && var.domain_config.acm_cert_arn == null)
    error_message = "must provide an acm_cert_arn if auto_acm_cert isn't true"
  }
}

variable "alb_config" {
  type = object({
    vpc_id          = string
    public_subnets  = list(string)
    private_subnets = list(string)
    security_groups = list(string)
  })
  default = null
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
  default = null
}

variable "assistants" {
  type = object({
    domain = optional(string)
    db     = object({
      regions             = optional(set(string))
      deletion_protection = optional(bool)
      cloud_provider      = optional(string)
    })
    containers = optional(object({
      cpu           = optional(number)
      memory        = optional(number)
      min_instances = optional(number)
      max_instances = optional(number)
    }))
  })
  default = null
}

variable "langflow" {
  type = object({
    domain     = optional(string)
    db_url     = optional(string)
    containers = optional(object({
      cpu           = optional(number)
      memory        = optional(number)
      min_instances = optional(number)
      max_instances = optional(number)
    }))
  })
  default = null
}

variable "vector_dbs" {
  type = list(object({
    name                = string
    regions             = optional(set(string))
    keyspace            = optional(string)
    cloud_provider      = optional(string)
    deletion_protection = optional(bool)
  }))
  nullable = false
  default  = []
}

# variable "chat_ui" {
#   type = object({
#     public_origin = string
#     task_model    = any
#     models        = any
#     mongodb_url   = string
#     api_keys = object({
#       hf_token             = optional(string)
#       openai_api_key       = optional(string)
#       perplexityai_api_key = optional(string)
#       cohere_api_key       = optional(string)
#       gemini_api_key       = optional(string)
#     })
#     vm_config = optional(object({
#       instance_type  = string
#       image_id       = string
#       subnet_id      = optional(string)
#       region_or_zone = optional(string)
#     }))
#   })
#   nullable = true
#   default  = null
# }
