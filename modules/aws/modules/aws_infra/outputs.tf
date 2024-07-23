output "vpc_id" {
  value = local.vpc_id
}

output "alb_dns_name" {
  value = {
    for component, output in module.alb : component => output.dns_name
  }
}

output "ecs_cluster_id" {
  value = module.ecs.cluster_id
}

output "target_group_arns" {
  value = {
    for config in var.components : config.name => try(module.alb[config.name].target_groups, module.alb["default"].target_groups)[config.name].arn
  }
}

output "security_groups" {
  value = [aws_security_group.ecs_cluster_sg.id]
}

output "private_subnets" {
  value = local.private_subnets
}

output "public_subnets" {
  value = local.public_subnets
}
