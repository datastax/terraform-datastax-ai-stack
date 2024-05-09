output "vpc_id" {
  value = length(module.aws_infra) > 0 ? module.aws_infra[0].vpc_id : null
}

output "alb_dns_name" {
  value = length(module.aws_infra) > 0 ? module.aws_infra[0].alb_dns_name : null
}
