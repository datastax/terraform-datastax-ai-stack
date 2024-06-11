output "langflow_fqdn" {
  value = module.langflow[*].fqdn
}

output "assistants_fqdn" {
  value = module.assistants[*].fqdn
}

output "db_ids" {
  value = zipmap(concat(module.assistants[*].db_id, values(module.vector_dbs)[*].db_id), concat(module.assistants[*].db_name, values(module.vector_dbs)[*].db_name))
}
