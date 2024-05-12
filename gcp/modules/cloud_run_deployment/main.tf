locals {
  service_name = "${var.container_info.name}-service"
}

resource "google_cloud_run_v2_service" "this" {
  name     = local.service_name
  project  = var.infrastructure.project_id
  location = var.infrastructure.location

  template {
    containers {
      image = var.container_info.image

      resources {
        limits = {
          cpu    = try(coalesce(var.config.container_limits.cpu), "1")
          memory = try(coalesce(var.config.container_limits.memory), "2048Mi")
        }
      }

      ports {
        container_port = var.container_info.port
        name           = "http1"
      }
    }
  }

  ingress = "INGRESS_TRAFFIC_ALL"
}

resource "google_cloud_run_service_iam_member" "public_access" {
  location = google_cloud_run_v2_service.this.location
  project  = google_cloud_run_v2_service.this.project
  service  = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "service_name" {
  value = local.service_name
}
