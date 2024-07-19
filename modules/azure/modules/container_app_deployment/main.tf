resource "azurerm_container_app" "this" {
  name = "${var.container_info.name}-service"

  container_app_environment_id = var.infrastructure.container_app_environment_id
  resource_group_name          = var.infrastructure.resource_group_name
  revision_mode                = "Single"

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = var.container_info.port

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    container {
      name    = var.container_info.name
      image   = "${var.container_info.image}:${try(coalesce(var.config.deployment.image_version), "latest")}"
      cpu     = try(coalesce(var.config.containers.cpu), 1)
      memory  = try(coalesce(var.config.containers.memory), "2Gi")
      command = var.container_info.entrypoint

      liveness_probe {
        port          = var.container_info.port
        transport     = "HTTP"
        path          = var.container_info.health_path
        initial_delay = 60
      }

      dynamic "env" {
        for_each = try(coalesce(var.config.containers.env), {})

        content {
          name  = env.key
          value = env.value
        }
      }
    }

    min_replicas = try(coalesce(var.config.deployment.min_instances), 0)
    max_replicas = try(coalesce(var.config.deployment.max_instances), 20)
  }

  lifecycle {
    ignore_changes = [ingress.0.custom_domain]
  }
}

output "fqdn" {
  value = azurerm_container_app.this.latest_revision_fqdn
}

output "id" {
  value = azurerm_container_app.this.id
}

output "domain_verification_id" {
  value = azurerm_container_app.this.custom_domain_verification_id
}

output "outbound_ip" {
  value = azurerm_container_app.this.outbound_ip_addresses
}
