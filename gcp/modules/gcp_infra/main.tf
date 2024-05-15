locals {
  project_id = coalesce(var.project_config.project_id, module.project-factory[0].project_id)
  location   = try(coalesce(var.cloud_run_config.location), data.google_cloud_run_locations.available.locations[0])
}

data "google_cloud_run_locations" "available" {
  project = local.project_id
}

module "project-factory" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 15.0"

  count = var.project_config != null ? 1 : 0

  name              = try(coalesce(var.project_config.project_options.name), "enterprise-gpts")
  random_project_id = true
  org_id            = try(var.project_config.project_options.org_id, null)
  billing_account   = var.project_config.project_options.billing_account
  activate_apis     = ["run.googleapis.com", "dns.googleapis.com"]
}

resource "random_id" "id" {
  byte_length = 8
}

resource "google_storage_bucket" "bucket_404" {
  name     = "enterprise-gpts-404-bucket-${random_id.id.hex}"
  project  = local.project_id
  location = local.location
}

resource "google_storage_bucket_object" "not_found_page" {
  name    = "404.html"
  bucket  = google_storage_bucket.bucket_404.name
  content = "Not Found"
}

resource "google_compute_backend_bucket" "backend_404" {
  name        = "backend-404"
  project     = local.project_id
  bucket_name = google_storage_bucket.bucket_404.name
  enable_cdn  = false
}

resource "random_id" "url_map" {
  keepers = {
    instances = base64encode(jsonencode(var.components))
  }
  byte_length = 1
}

resource "google_compute_url_map" "url_map" {
  name    = "enterprise-gpts-url-map-${random_id.url_map.hex}"
  project = local.project_id

  dynamic "host_rule" {
    for_each = var.components

    content {
      hosts        = [host_rule.value.domain]
      path_matcher = host_rule.key
    }
  }

  dynamic "path_matcher" {
    for_each = var.components

    content {
      name            = path_matcher.key
      default_service = module.lb-http.backend_services[path_matcher.key].id
    }
  }

  default_url_redirect {
    strip_query            = false
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
  }
}

module "lb-http" {
  source  = "terraform-google-modules/lb-http/google//modules/serverless_negs"
  version = "~> 10.0"

  name    = "enterprise-gpts-lb"
  project = local.project_id

  ssl                             = true
  managed_ssl_certificate_domains = values(var.components)[*].domain
  random_certificate_suffix       = true
  https_redirect                  = true
  url_map                         = google_compute_url_map.url_map.self_link

  backends = {
    for name, component in var.components : name => {
      description = null
      groups      = [
        { group = google_compute_region_network_endpoint_group.serverless_neg[name].id }
      ]
      enable_cdn = false
      iap_config = {
        enable = false
      }
      log_config = {
        enable = false
      }
    }
  }
}

resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  for_each = var.components

  name                  = "enterprise-gpts-${each.key}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = local.location
  project               = local.project_id

  cloud_run {
    service = each.value.service_name
  }
}

locals {
  dns_names = try(var.domain_config.dns_names, {})
  auto_cloud_dns_setup = try(var.domain_config.auto_cloud_dns_setup, null) == true

  # Create a temporary grouping of DNS names to components names (dns_names may be duplicated)
  _dns_names_to_components = flatten([
    for name, config in var.components : [
      {
        dns_name = try(local.dns_names[config.name], local.dns_names["default"])
        name     = name
      }
    ]
  ])

  # Picks out the unique DNS names
  unique_dns_names = distinct(local._dns_names_to_components[*]["dns_name"])

  # Create a mapping of DNS names to a singular name which combines the names of the components that use it
  # e.g. { "example.com" = "langflow-astra-assistants" }
  dns_name_to_components = {
    for dns_name in local.unique_dns_names : dns_name =>
    join("-", [for pair in local._dns_names_to_components : pair["name"] if pair["dns_name"] == dns_name])
  }
}

resource "google_dns_managed_zone" "zones" {
  for_each = local.dns_name_to_components

  name     = "egpts-${each.value}-zone"
  dns_name = each.key
  project  = local.project_id
}

resource "google_dns_record_set" "a_records" {
  for_each = {
    for name, config in var.components : name => config
    if local.auto_cloud_dns_setup
  }

  name         = each.value.domain
  managed_zone = google_dns_managed_zone.zones[try(local.dns_names[each.value.name], local.dns_names["default"])].name
  type         = "A"
  ttl          = 300
  rrdatas      = [module.lb-http.external_ip]
  project      = local.project_id
}

output "project_id" {
  value = local.project_id
}

output "load_balancer_ip" {
  value = module.lb-http.external_ip
}

output "location" {
  value = local.location
}

output "name_servers" {
  value = {
    for name, zone in google_dns_managed_zone.zones : name => zone.name_servers
  }
}
