output "langflow_fqdn" {
  value = module.langflow[*].fqdn
}

output "assistants_fqdn" {
  value = module.assistants[*].fqdn
}
