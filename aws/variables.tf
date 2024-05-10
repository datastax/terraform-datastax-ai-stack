variable "aws_config" {
  type = object({
    domain_config = optional(object({
      auto_route53_dns_config = optional(bool)
      auto_https_cert         = optional(bool)
      https_cert_arn          = optional(string)
    }))
    alb_config = optional(object({
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
  nullable = true
  default  = null
}

variable "assistants" {
  type = object({
    domain = object({
      name             = string
      hosted_zone_id   = optional(string)
      hosted_zone_name = optional(string)
    })
    db = optional(object({
      regions             = set(string)
      deletion_protection = optional(bool)
      cloud_provider      = optional(string)
    }))
    containers = optional(object({
      cpu           = optional(number)
      memory        = optional(number)
      desired_count = optional(number)
    }))
    infrastructure = optional(object({
      cluster          = string
      target_group_arn = string
      security_groups  = set(string)
      subnets          = set(string)
    }))
  })
  nullable = true
  default  = null
}

variable "langflow" {
  type = object({
    domain = object({
      name             = string
      hosted_zone_id   = optional(string)
      hosted_zone_name = optional(string)
    })
    containers = optional(object({
      cpu    = optional(number)
      memory = optional(number)
    }))
    infrastructure = optional(object({
      cluster          = string
      target_group_arn = string
      security_groups  = set(string)
      subnets          = set(string)
    }))
  })
  nullable = true
  default  = null
}

variable "vector_dbs" {
  type = list(object({
    name                = string
    regions             = set(string)
    keyspace            = optional(string)
    cloud_provider      = optional(string)
    deletion_protection = optional(bool)
  }))
  default = []
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
