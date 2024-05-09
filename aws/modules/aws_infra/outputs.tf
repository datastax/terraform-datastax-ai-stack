output "vpc_id" {
  value = local.vpc_id
}

output "alb_dns_name" {
  value = module.alb.dns_name
}

output "ecs_cluster_id" {
  value = module.ecs.cluster_id
}

output "target_groups" {
  value = module.alb.target_groups
}

output "security_groups" {
  value = [aws_security_group.ecs_cluster_sg.id]
}

output "subnet_ids" {
  value = local.private_subnets
}
