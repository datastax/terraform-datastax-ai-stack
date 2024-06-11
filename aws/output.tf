output "vpc_id" {
  value = module.aws_infra.vpc_id
}

output "alb_dns_name" {
  value = module.aws_infra.alb_dns_name
}

output "db_ids" {
  value = zipmap(concat(module.assistants[*].db_id, values(module.vector_dbs)[*].db_id), concat(module.assistants[*].db_name, values(module.vector_dbs)[*].db_name))
}
