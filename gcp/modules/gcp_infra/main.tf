locals {
  project_id = coalesce(var.gcp_config.project_id, module.project-factory[0].project_id)
  domain     = var.gcp_config.project_id != null ? "" : module.project-factory[0].domain
}

module "project-factory" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 15.0"

  count = var.gcp_config.project_id != null ? 0 : 1

  name              = try(coalesce(var.gcp_config.project_options.name), "enterprise-gpts")
  random_project_id = true
  org_id            = try(var.gcp_config.project_options.org_id, null)
  billing_account   = var.gcp_config.project_options.billing_account
  activate_apis     = ["run.googleapis.com"]
}

output "project_id" {
  value = local.project_id
}
