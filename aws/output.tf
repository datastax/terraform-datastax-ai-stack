output "vpc_id" {
  value = module.aws_infra.vpc_id
}

output "alb_dns_name" {
  value = module.aws_infra.alb_dns_name
}
