data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  create_vpc = var.aws_config != null
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8.1"

  count = local.create_vpc ? 1 : 0

  name = "enterprise-gpts-vpc"
  tags = {
    Project = "enterprise-gpts"
  }

  azs                = slice(data.aws_availability_zones.available.names, 0, 2)
  cidr               = "10.0.0.0/16"
  create_igw         = true
  enable_nat_gateway = true
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
  single_nat_gateway = true
}

locals {
  vpc_id          = try(coalesce(var.aws_config.alb_config.vpc_id), module.vpc[0].vpc_id)
  public_subnets  = try(coalesce(var.aws_config.alb_config.public_subnets), module.vpc[0].public_subnets)
  private_subnets = try(coalesce(var.aws_config.alb_config.private_subnets), module.vpc[0].private_subnets)
  security_groups = try(coalesce(var.aws_config.alb_config.security_groups), [module.vpc[0].default_security_group_id])
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.9.0"

  load_balancer_type = "application"

  name = "enterprise-gpts-alb"
  tags = {
    Project = "enterprise-gpts"
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
  }

  security_group_egress_rules = {
    all_http = {
      from_port   = 0
      to_port     = 65535
      protocol    = "TCP"
      description = "Permit all outgoing requests to the internet"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    #     http = {
    #       port     = 80
    #       protocol = "HTTP"
    #       redirect = {
    #         port        = 443
    #         protocol    = "HTTPS"
    #         status_code = "HTTP_301"
    #       }
    #     }
    #     https = {
    #       port     = 443
    #       protocol = "HTTPS"
    #       rules    = {
    #         for config in var.components : config.name => {
    #           actions    = [{ type = "forward", target_group_key = config.name }]
    #           conditions = [
    #             {
    #               host_header = {
    #                 values = ["${coalesce(config.subdomain, config.name)}.${var.aws_config.domain}"]
    #               }
    #             }
    #           ]
    #         }
    #       }
    #       fixed_response = {
    #         content_type = "text/plain"
    #         status_code  = "404"
    #         message_body = "Not Found"
    #       }
    #     }
    http = {
      port     = 80
      protocol = "HTTP"
      rules    = {
        for config in var.components : config.name => {
          actions    = [{ type = "forward", target_group_key = config.name }]
          conditions = [{ host_header = { values = [config.domain.name] } }]
        }
      }
      fixed_response = {
        content_type = "text/plain"
        status_code  = "404"
        message_body = "Not Found"
      }
    }
  }

  target_groups = {
    for config in var.components : config.name => {
      name_prefix       = config.name_prefix
      port              = config.port
      protocol          = "HTTP"
      target_type       = "ip"
      create_attachment = false
    }
  }
}

data "aws_route53_zone" "primary" {
  for_each = {
    for idx, config in var.components : config.name => config
    if var.aws_config.auto_route53_dns_config == true
  }

  name         = each.value.domain.hosted_zone_name
  zone_id      = each.value.domain.hosted_zone_id
  private_zone = false
}

resource "aws_route53_record" "service_a_records" {
  for_each = {
    for idx, config in var.components : config.name => config
    if var.aws_config.auto_route53_dns_config == true
  }

  name    = "${each.value.domain.name}."
  type    = "A"
  zone_id = data.aws_route53_zone.primary[each.value.name].zone_id

  alias {
    name                   = "${module.alb.dns_name}."
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.11.1"

  cluster_name = "enterprise-gpts-ecs-cluster"

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        base   = try(coalesce(var.aws_config.fargate_config.capacity_provider_weights.default_base), 0)
        weight = try(coalesce(var.aws_config.fargate_config.capacity_provider_weights.default_weight), 0)
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        base   = try(coalesce(var.aws_config.fargate_config.capacity_provider_weights.spot_base), 0)
        weight = try(coalesce(var.aws_config.fargate_config.capacity_provider_weights.default_weight), 100)
      }
    }
  }
}

resource "aws_security_group" "ecs_cluster_sg" {
  vpc_id = local.vpc_id

  name = "enterprise-gpts-ecs-cluster-sg"

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id]
    self            = true
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
