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
  activate_apis     = compact(["run.googleapis.com", local.auto_cloud_dns_setup ? "dns.googleapis.com" : ""])
}

resource "random_id" "url_map" {
  keepers = {
    instances = base64encode(jsonencode(values(var.components)[*].domain))
  }
  byte_length = 1
}

resource "google_compute_url_map" "url_map" {
  name    = "enterprise-gpts-url-map-${random_id.url_map.hex}"
  project = local.project_id

  dynamic "host_rule" {
    for_each = {
      for name, config in var.components : name => config.domain
      if config.domain != null
    }

    content {
      hosts        = [host_rule.value]
      path_matcher = host_rule.key
    }
  }

  dynamic "path_matcher" {
    for_each = {
      for name, config in var.components : name => config
      if config.domain != null
    }

    content {
      name            = path_matcher.key
      default_service = module.lb-http.backend_services[path_matcher.key].id
    }
  }

  default_url_redirect {
    strip_query            = false
    redirect_response_code = "FOUND"
  }
}

module "lb-http" {
  source  = "terraform-google-modules/lb-http/google//modules/serverless_negs"
  version = "~> 10.0"

  name    = "enterprise-gpts-lb-${random_id.url_map.hex}"
  project = local.project_id

  ssl                             = true
  managed_ssl_certificate_domains = compact(values(var.components)[*].domain)
  random_certificate_suffix       = true
  https_redirect                  = true
  url_map                         = google_compute_url_map.url_map.self_link
  create_url_map                  = false

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
  managed_zones = coalesce(var.domain_config.managed_zones, {})
  auto_cloud_dns_setup = coalesce(var.domain_config.auto_cloud_dns_setup, false)

  # Lookup table which resolves a service to a { dns_name } or { zone_name }
  _managed_zones_lut = {
    for name, config in var.components : name => try(local.managed_zones[config.name], local.managed_zones["default"])
    if local.auto_cloud_dns_setup
  }

  # Create a temporary grouping of DNS names to components names (dns_names may be duplicated)
  _dns_names_to_services = flatten([
    for name, config in var.components : [
      {
        dns_name     = local._managed_zones_lut[name]["dns_name"]
        service_name = name
      }
    ] if try(local._managed_zones_lut[name]["dns_name"], null) != null
  ])

  # Create a mapping of DNS names to a singular name which combines the names of the components that use it
  # e.g. { default = { dns_name = "example.com." } } => { "example.com." = "egpts-langflow-assistants-zone" }
  dns_name_to_combined_name = {
    for dns_name in toset(local._dns_names_to_services[*]["dns_name"]) : dns_name =>
    join("-", [for pair in local._dns_names_to_services : pair["service_name"] if pair["dns_name"] == dns_name])
    if local.auto_cloud_dns_setup
  }

  # Find the zone name given a service name (e.g. "langflow" => "egpts-langflow-assistants-zone")
  # Passes through a google_dns_managed_zone data source for validation purposes (instead of blindly using the value)
  managed_zones_lut = {
    for name, config in var.components : name =>
    (local._managed_zones_lut[config.name]["dns_name"] != null
      ? google_dns_managed_zone.zones[
      [for pair in local._dns_names_to_services : pair["dns_name"] if pair["service_name"] == name][0]
      ].name
      : local._managed_zones_lut[config.name]["zone_name"])
    if local.auto_cloud_dns_setup
  }
}

resource "google_dns_managed_zone" "zones" {
  for_each = local.dns_name_to_combined_name
  name     = "egpts-${each.value}-zone"
  dns_name = each.key
  project  = local.project_id
}

resource "google_dns_record_set" "a_records" {
  for_each = {
    for name, config in var.components : name => config
    if local.auto_cloud_dns_setup
  }

  name         = "${each.value.domain}."
  managed_zone = local.managed_zones_lut[each.key]
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
