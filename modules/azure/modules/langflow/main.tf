locals {
  container_info = {
    name        = "langflow"
    image       = "langflowai/langflow"
    port        = 7860
    health_path = "/health"
  }

  using_managed_db = var.config.postgres_db != null

  postgres_url = (local.using_managed_db
    ? "postgresql://psqladmin:${random_string.admin_password[0].result}@${azurerm_postgresql_flexible_server.this[0].fqdn}:5432/postgres"
    : null
  )

  merged_env = (try(var.config.containers.env["LANGFLOW_DATABASE_URL"], null) == null && local.postgres_url != null
    ? merge({ LANGFLOW_DATABASE_URL = local.postgres_url }, {
      for k, v in try(coalesce(var.config.containers.env), {}) : k => v if k != "LANGFLOW_DATABASE_URL"
    })
    : try(coalesce(var.config.containers.env), {})
  )

  merged_containers = merge(try(coalesce(var.config.containers), {}), { env = local.merged_env })
  merged_config     = merge(try(coalesce(var.config), {}), { containers = local.merged_containers })
}

output "container_info" {
  value = local.container_info
}

output "fqdn" {
  value = module.container_app_deployment.fqdn
}

output "id" {
  value = module.container_app_deployment.id
}

output "domain_verification_id" {
  value = module.container_app_deployment.domain_verification_id
}

module "container_app_deployment" {
  source         = "../container_app_deployment"
  container_info = local.container_info
  config         = local.merged_config
  infrastructure = var.infrastructure
}

resource "random_string" "admin_password" {
  count = local.using_managed_db ? 1 : 0

  length           = 16
  override_special = "%*()-_=+[]{}?"
}

resource "azurerm_postgresql_flexible_server" "this" {
  count = local.using_managed_db != false ? 1 : 0

  name                = "langflow-managed-db"
  location            = coalesce(var.config.postgres_db.location, var.infrastructure.resource_group_location)
  resource_group_name = var.infrastructure.resource_group_name

  administrator_login    = "psqladmin"
  administrator_password = random_string.admin_password[0].result

  sku_name   = var.config.postgres_db.sku_name
  version    = "16"
  storage_mb = var.config.postgres_db.max_storage

  backup_retention_days = 7
  auto_grow_enabled     = true

  lifecycle {
    ignore_changes = [zone]
  }
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_container_apps" {
  count = local.using_managed_db != false ? 1 : 0

  name             = "allow_container_apps"
  start_ip_address = module.container_app_deployment.outbound_ip[0]
  end_ip_address   = module.container_app_deployment.outbound_ip[0]
  server_id        = azurerm_postgresql_flexible_server.this[0].id
}
