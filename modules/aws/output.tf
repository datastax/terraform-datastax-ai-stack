output "vpc_id" {
  value = try(module.aws_infra[0].vpc_id, null)
}

output "alb_dns_name" {
  value = try(module.aws_infra[0].alb_dns_name, null)
}

output "db_ids" {
  value = zipmap(concat(module.assistants[*].db_id, values(module.vector_dbs)[*].db_id), concat(module.assistants[*].db_name, values(module.vector_dbs)[*].db_name))
}
