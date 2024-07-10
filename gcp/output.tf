output "load_balancer_ip" {
  value = try(module.gcp_infra[0].load_balancer_ip, null)
}

output "project_id" {
  value = try(module.gcp_infra[0].project_id, null)
}

output "name_servers" {
  value = try(module.gcp_infra[0].name_servers, null)
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
