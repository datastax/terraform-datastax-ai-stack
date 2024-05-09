module "cloud_run" {
  source  = "GoogleCloudPlatform/cloud-run/google"
  version = "~> 0.10.0"

  service_name = var.container_info.name
  project_id   = var.infrastructure.project_id
  location     = var.infrastructure.location
  image        = var.container_info.image

  limits = {
    cpu    = try(coalesce(var.config.container_limits.cpu), "1.0")
    memory = try(coalesce(var.config.container_limits.memory), "2048Mi")
  }

  ports = {
    name = "http1"
    port = var.container_info.port
  }

  verified_domain_name = compact([var.config.domain])
}

data "google_iam_policy" "no_auth" {
  binding {
    role    = "roles/run.invoker"
    members = ["allUsers"]
  }
}

resource "google_cloud_run_service_iam_policy" "no_auth" {
  count       = var.config.make_public != false ? 1 : 0
  location    = module.cloud_run.location
  project     = module.cloud_run.project_id
  service     = module.cloud_run.service_name
  policy_data = data.google_iam_policy.no_auth.policy_data
}
