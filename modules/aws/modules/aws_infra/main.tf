data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8.1"

  count = var.alb_config == null ? 1 : 0

  name = "datastax-vpc"
  tags = {
    Project = "datastax"
  }

  azs                = try(coalesce(var.deployment_defaults.vpc_availability_zones), slice(data.aws_availability_zones.available.names, 0, 2))
  cidr               = "10.0.0.0/16"
  create_igw         = true
  enable_nat_gateway = true
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
  single_nat_gateway = true
}

locals {
  vpc_id          = try(var.alb_config.vpc_id, module.vpc[0].vpc_id)
  public_subnets  = try(var.alb_config.public_subnets, module.vpc[0].public_subnets)
  private_subnets = try(var.alb_config.private_subnets, module.vpc[0].private_subnets)
  security_groups = try(var.alb_config.security_groups, [module.vpc[0].default_security_group_id])
  certificate_arn = try(aws_acm_certificate.service_cert[0].arn, var.domain_config.acm_cert_arn)
}

locals {
  _specific_albs = {
    for config in var.components : config.name => [config] if config.domain == null
  }

  _default_alb = {
    default = [for config in var.components : config if config.domain != null]
  }

  albs = (length(local._specific_albs) != length(var.components)
    ? merge(local._specific_albs, local._default_alb)
    : local._specific_albs
  )
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.9.0"

  for_each   = local.albs
  depends_on = [aws_acm_certificate_validation.certificate_validation]

  enable_deletion_protection = false

  name = "datastax-${each.key}-alb"
  tags = {
    Project = "datastax"
  }

  vpc_id          = local.vpc_id
  subnets         = local.public_subnets
  security_groups = local.security_groups

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      protocol    = "TCP"
      description = "Permit incoming HTTP requests from the internet"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      protocol    = "TCP"
      description = "Permit incoming HTTPS requests from the internet"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all = {
      from_port   = 0
      to_port     = 65535
      protocol    = "TCP"
      description = "Permit all outgoing requests to the internet"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = [
    {
      http = {
        port     = 80
        protocol = "HTTP"
        redirect = {
          port        = 443
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }
      https = {
        port            = 443
        protocol        = "HTTPS"
        certificate_arn = local.certificate_arn
        rules = {
          for config in each.value : config["name"] => {
            actions    = [{ type = "forward", target_group_key = config["name"] }]
            conditions = [{ host_header = { values = [config["domain"]] } }]
          }
        }
        fixed_response = {
          content_type = "text/plain"
          status_code  = "404"
          message_body = "Not Found"
        }
      }
    },
    {
      http = {
        port     = 80
        protocol = "HTTP"
        forward = {
          target_group_key = each.value[0]["name"]
        }
      }
    }
  ][each.key == "default" ? 0 : 1]

  target_groups = {
    for config in each.value : config["name"] => {
      name_prefix       = config["name_prefix"]
      port              = config["port"]
      protocol          = "HTTP"
      target_type       = "ip"
      create_attachment = false
    }
  }
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.11.1"

  cluster_name = "datastax-ecs-cluster"

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        base   = try(coalesce(var.deployment_defaults.capacity_provider_weights.default_base), 20)
        weight = try(coalesce(var.deployment_defaults.capacity_provider_weights.default_weight), 0)
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        base   = try(coalesce(var.deployment_defaults.capacity_provider_weights.spot_base), 0)
        weight = try(coalesce(var.deployment_defaults.capacity_provider_weights.default_weight), 80)
      }
    }
  }
}

resource "aws_security_group" "ecs_cluster_sg" {
  name   = "datastax-cluster-sg"
  vpc_id = local.vpc_id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = values(module.alb)[*].security_group_id
    self            = true
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
