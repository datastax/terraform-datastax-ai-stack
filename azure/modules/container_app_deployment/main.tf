locals {
  service_name = "${var.container_info.name}-service"
}

resource "azurerm_container_app" "my_first_app" {
  name = local.service_name

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
      image   = var.container_info.image
      cpu = try(coalesce(var.config.containers.cpu), 1)
      memory = try(coalesce(var.config.containers.memory), "2Gi")
      command = var.container_info.entrypoint

      liveness_probe {
        port          = var.container_info.port
        transport     = "HTTP"
        path          = var.container_info.health_path
        initial_delay = 60
      }

      dynamic "env" {
        for_each = coalesce(var.container_info.env, {})

        content {
          name  = env.value.name
          value = env.value.value
        }
      }
    }

    min_replicas = try(coalesce(var.config.containers.min_instances), 0)
    max_replicas = try(coalesce(var.config.containers.max_instances), 20)
  }
}

resource "null_resource" "configure_hostname" {
  provisioner "local-exec" {}
}

output "fqdn" {
  value = azurerm_container_app.my_first_app.latest_revision_fqdn
}
