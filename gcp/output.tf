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
