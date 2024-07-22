locals {
  csql_instances = var.using_managed_db ? [var.container_info.csql_instance] : []
}

resource "google_cloud_run_v2_service" "this" {
  name     = var.container_info.service_name
  project  = var.infrastructure.project_id
  location = var.config.deployment.location

  template {
    service_account = try(coalesce(var.config.deployment.service_account), try(google_service_account.cloud_run_sa[0].email, null))

    containers {
      image   = "${var.container_info.image_name}:${try(coalesce(var.config.deployment.image_version), "latest")}"
      command = var.container_info.entrypoint

      liveness_probe {
        http_get {
          path = var.container_info.health_path
        }
        initial_delay_seconds = 120
      }

      resources {
        limits = {
          cpu    = try(coalesce(var.config.containers.cpu), "1")
          memory = try(coalesce(var.config.containers.memory), "2048Mi")
        }
      }

      ports {
        container_port = var.container_info.port
        name           = "http1"
      }

      dynamic "env" {
        for_each = try(coalesce(var.config.containers.env), {})

        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "volume_mounts" {
        for_each = toset(local.csql_instances)

        content {
          name       = "cloudsql"
          mount_path = "/cloudsql"
        }
      }
    }

    scaling {
      min_instance_count = try(coalesce(var.config.deployment.min_instances), 0)
      max_instance_count = try(coalesce(var.config.deployment.max_instances), 20)
    }

    dynamic "volumes" {
      for_each = toset(local.csql_instances)

      content {
        name = "cloudsql"

        cloud_sql_instance {
          instances = [var.container_info.csql_instance]
        }
      }
    }
  }

  ingress = var.config.domain != null ? "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER" : "INGRESS_TRAFFIC_ALL"
}

resource "google_cloud_run_service_iam_member" "public_access" {
  location = google_cloud_run_v2_service.this.location
  service  = google_cloud_run_v2_service.this.name
  project  = var.infrastructure.project_id
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_service_account" "cloud_run_sa" {
  count        = var.using_managed_db ? 1 : 0
  project      = var.infrastructure.project_id
  account_id   = "cloud-run-sa"
  display_name = "Cloud Run Service Account"
}

resource "google_project_iam_member" "cloud_sql_client" {
  count   = var.using_managed_db ? 1 : 0
  project = var.infrastructure.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_run_sa[0].email}"
}

output "service_uri" {
  value = google_cloud_run_v2_service.this.uri
}
