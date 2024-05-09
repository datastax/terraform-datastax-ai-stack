# data "astra_available_regions" "this" {}

locals {
  cloud_provider = try(coalesce(var.config.cloud_provider), var.cloud_provider)

#   filtered_regions = toset([
#     for result in data.astra_available_regions.this.results : result.region
#     if result.cloud_provider == upper(local.cloud_provider)
#   ])

#   regions = try(coalesce(var.config.regions), [tolist(local.filtered_regions)[0]])
}

resource "astra_database" "astra_vector_dbs" {
  cloud_provider      = local.cloud_provider
  keyspace            = var.config.keyspace
  name                = var.config.name
  deletion_protection = var.config.deletion_protection
#   regions             = local.regions
  regions             = var.config.regions
  db_type             = "vector"
}
