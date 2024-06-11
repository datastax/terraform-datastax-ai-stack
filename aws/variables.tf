variable "domain_config" {
  type = object({
    auto_route53_setup = bool
    hosted_zones       = optional(map(object({
      zone_id   = optional(string)
      zone_name = optional(string)
    })))
    acm_cert_arn  = optional(string)
  })
  nullable = false

  validation {
    condition     = !(var.domain_config.auto_route53_setup == true && length(var.domain_config.hosted_zones) == 0)
    error_message = "auto_route53_setup requires hosted_zones to be provided"
  }

  validation {
    condition     = !(var.domain_config.auto_route53_setup == false && var.domain_config.acm_cert_arn == null)
    error_message = "must provide an acm_cert_arn if auto_route53_setup isn't true"
  }

  description = <<EOF
    Options for setting up domain names and DNS records.

    auto_route53_setup: If true, Route53 will be automatically set up. hosted_zones must be set if this is true. Otherwise, you must set each domain to the output load_balancer_ip w/ an A record.

    hosted_zones: A map of components (or a default value) to their hosted_zones zones. The valid keys are {default, langflow, assistants}. For each, either zone_id or zone_name must be set.
      zone_name: The name of the existing hosted zone to use. Must not be a private zone.
      zone_id: The ID of the existing hosted zone to use.

    acm_cert_arn: The ARN of the ACM certificate to use. Required if auto_route53_setup is false. If auto_route53_setup is true, you may choose to set this; otherwise, one is manually created.
  EOF
}

variable "infrastructure" {
  type = object({
    vpc_id          = string
    public_subnets  = list(string)
    private_subnets = list(string)
    security_groups = list(string)
  })
  default = null

  description = <<EOF
    Required fields to attach the ALB and ECS instances to. If not set, a new VPC will be created w/ a default security group.

    vpc_id: The ID of the VPC to create the ALB in.
    public_subnets: A list of public subnet IDs to create the ALB in.
    private_subnets: A list of private subnet IDs to create the ECS instances in.
    security_groups: A list of security group IDs to attach to the ALB.
  EOF
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
  default = null

  description = <<EOF
    Sets global options for the ECS Fargate instances.

    capacity_provider_weights: The weights to assign to the capacity providers. If not set, it's a 20/80 split between Fargate and Fargate Spot.
      default_base: The base number of tasks to run on Fargate.
      default_weight: The relative weight for Fargate when scaling tasks.
      spot_base: The base number of tasks to run on Fargate Spot.
      spot_weight: The relative weight for Fargate Spot when scaling tasks.
  EOF
}

variable "assistants" {
  type = object({
    domain = string
    env    = optional(map(string))
    db     = optional(object({
      regions             = optional(set(string))
      deletion_protection = optional(bool)
      cloud_provider      = optional(string)
    }))
    containers = optional(object({
      cpu           = optional(number)
      memory        = optional(number)
      min_instances = optional(number)
      max_instances = optional(number)
    }))
  })
  default = null

  description = <<EOF
    Options for the Astra Assistant API service.

    domain: The domain name to use for the service; used in the listener routing rules.

    env: Environment variables to set for the service.

    db: Options for the database Astra Assistants uses.
      regions: The regions to deploy the database to. Defaults to the first available region.
      deletion_protection: Whether to enable deletion protection on the database.
      cloud_provider: The cloud provider to use for the database. Defaults to "gcp".

    containers: Options for the ECS service.
      cpu: The amount of CPU to allocate to the service. Defaults to 1024.
      memory: The amount of memory to allocate to the service. Defaults to 2048 (Mi).
      min_instances: The minimum number of instances to run. Defaults to 1.
      max_instances: The maximum number of instances to run. Defaults to 100.
  EOF
}

variable "langflow" {
  type = object({
    domain     = string
    env        = optional(map(string))
    containers = optional(object({
      cpu           = optional(number)
      memory        = optional(number)
      min_instances = optional(number)
      max_instances = optional(number)
    }))
  })
  default = null

  description = <<EOF
    Options for the Langflow service.

    domain: The domain name to use for the service; used in the listener routing rules.

    env: Environment variables to set for the service.

    containers: Options for the ECS service.
      cpu: The amount of CPU to allocate to the service. Defaults to 1024.
      memory: The amount of memory to allocate to the service. Defaults to 2048 (Mi).
      min_instances: The minimum number of instances to run. Defaults to 1.
      max_instances: The maximum number of instances to run. Defaults to 100.
  EOF
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

  description = <<EOF
    Quickly sets up vector-enabled Astra Databases for your project.

    name: The name of the database to create.

    regions: The regions to deploy the database to. Defaults to the first available region.

    keyspace: The keyspace to use for the database. Defaults to "default_keyspace".

    cloud_provider: The cloud provider to use for the database. Defaults to "gcp".

    deletion_protection: Whether to enable deletion protection on the database.
  EOF
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
