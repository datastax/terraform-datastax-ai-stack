data "astra_available_regions" "this" {
  region_type    = "vector"
  cloud_provider = var.cloud_provider
  only_enabled   = true
}

locals {
  cloud_provider = coalesce(var.config.cloud_provider, var.cloud_provider)

  filtered_regions = [
    for region in data.astra_available_regions.this.results : region.region
    if !region.reserved_for_qualified_users
  ]

  regions = coalesce(var.config.regions, [local.filtered_regions[0]])

  keyspaces = coalesce(var.config.keyspaces, [])

  first_keyspace = length(local.keyspaces) > 0 ? local.keyspaces[0] : null
  rest_keyspaces = length(local.keyspaces) > 1 ? slice(local.keyspaces, 1, length(local.keyspaces)) : []
}

resource "astra_database" "astra_vector_db" {
  cloud_provider      = local.cloud_provider
  keyspace            = local.first_keyspace
  name                = var.config.name
  deletion_protection = coalesce(var.config.deletion_protection, false)
  regions             = local.regions
  db_type             = "vector"
}

resource "astra_keyspace" "astra_keyspaces" {
  for_each    = toset(local.rest_keyspaces)
  database_id = astra_database.astra_vector_db.id
  name        = each.key
}

output "db_id" {
  value = astra_database.astra_vector_db.id
}

output "db_name" {
  value = var.config.name
}
