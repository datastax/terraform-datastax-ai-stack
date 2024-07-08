output "load_balancer_ip" {
  value = module.gcp_infra.load_balancer_ip
}

output "project_id" {
  value = module.gcp_infra.project_id
}

output "name_servers" {
  value = module.gcp_infra.name_servers
}

output "service_uris" {
  value = {
    for key, uri in {
      langflow   = try(var.langflow.domain, null) != null ? ["https://${var.langflow.domain}"] : module.langflow[*].service_uri
      assistants = try(var.assistants.domain, null) != null ? ["https://${var.assistants.domain}"] : module.assistants[*].service_uri
    } : key => uri[0] if length(uri) > 0
  }
}

output "db_ids" {
  value = zipmap(concat(module.assistants[*].db_id, values(module.vector_dbs)[*].db_id), concat(module.assistants[*].db_name, values(module.vector_dbs)[*].db_name))
}