output "langflow_fqdn" {
  value = module.langflow[*].fqdn
}

output "assistants_fqdn" {
  value = module.assistants[*].fqdn
}

output "db_ids" {
  # value = zipmap(concat(module.assistants[*].db_name, module.vector_dbs[*].db_name), concat(module.assistants[*].db_id, module.vector_dbs[*].db_id))
  value = module.vector_dbs
}
