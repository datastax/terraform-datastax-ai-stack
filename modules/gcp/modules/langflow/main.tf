locals {
  service_name = "langflow-service"

  container_info = {
    service_name  = local.service_name
    image_name    = "langflowai/langflow"
    port          = 7860
    health_path   = "/health"
    csql_instance = try(google_sql_database_instance.this[0].connection_name, null)
  }

  using_managed_db = var.config.managed_db != null

  postgres_url = (local.using_managed_db
    ? "postgres://psqladmin:${random_string.admin_password[0].result}@/${google_sql_database.this[0].name}?host=/cloudsql/${google_sql_database_instance.this[0].connection_name}"
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

output "service_name" {
  value = local.service_name
}

output "service_uri" {
  value = module.cloud_run_deployment.service_uri
}

module "cloud_run_deployment" {
  source         = "../cloud_run_deployment"
  container_info = local.container_info
  infrastructure = var.infrastructure
  config         = local.merged_config
}

resource "google_sql_database_instance" "this" {
  count = local.using_managed_db ? 1 : 0

  name             = "dtsx-langflow-postgres-main-instance"
  database_version = "POSTGRES_16"
  project          = var.infrastructure.project_id

  region              = var.config.managed_db.region
  deletion_protection = var.config.managed_db.deletion_protection

  settings {
    tier = var.config.managed_db.tier

    ip_configuration {
      ssl_mode = "ENCRYPTED_ONLY"
    }

    disk_size             = try(coalesce(var.config.managed_db.initial_storage), 10)
    disk_autoresize_limit = try(coalesce(var.config.managed_db.max_storage), 10)
  }
}

resource "google_sql_database" "this" {
  count = local.using_managed_db ? 1 : 0

  name     = "dtsx-langflow-postgres-db"
  instance = google_sql_database_instance.this[0].name
  project  = var.infrastructure.project_id
}

resource "random_string" "admin_password" {
  count = local.using_managed_db ? 1 : 0

  length           = 16
  override_special = "%*()-_=+[]{}?"
}

resource "google_sql_user" "admin" {
  count = local.using_managed_db ? 1 : 0

  name     = "psqladmin"
  instance = google_sql_database_instance.this[0].name
  password = random_string.admin_password[0].result
  project  = var.infrastructure.project_id
}
