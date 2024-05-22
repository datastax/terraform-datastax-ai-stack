data "astra_available_regions" "this" {
  region_type    = "vector"
  cloud_provider = var.cloud_provider
  only_enabled   = true
}

locals {
  cloud_provider = try(coalesce(var.config.cloud_provider), var.cloud_provider)

  filtered_regions = [
    for region in data.astra_available_regions.this.results : region.region
    if !region.reserved_for_qualified_users
  ]

  regions = try(coalesce(var.config.regions), [local.filtered_regions[0]])
}

resource "astra_database" "astra_vector_dbs" {
  cloud_provider      = local.cloud_provider
  keyspace            = var.config.keyspace
  name                = var.config.name
  deletion_protection = var.config.deletion_protection
  regions             = local.regions
  db_type             = "vector"
}
