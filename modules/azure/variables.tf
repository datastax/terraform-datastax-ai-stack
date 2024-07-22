variable "resource_group_config" {
  type = object({
    resource_group_name = optional(string)
    create_resource_group = optional(object({
      name     = string
      location = string
    }))
  })
  default = null

  validation {
    condition     = try(var.resource_group_config.resource_group_name != null && var.resource_group_config.create_resource_group == null || var.resource_group_config.resource_group_name == null && var.resource_group_config.create_resource_group != null, true)
    error_message = "Either resource_group_name or create_resource_group must be set"
  }

  description = <<EOF
    Sets the resource group to use for the deployment. If resource_group_name is set, that group will be used. If create_resource_group is set, a group will be created with the given options. One of the two must be set.

    resource_group_name: The name of the resource group to use.

    create_resource_group: Options to use when creating a new resource group.
      name: The name of the resource group to create.
      location: The location to create the resource group in (e.g. "East US").

    If further customization is desired, the resource group can be created manually and the resource_group_name can be set.
  EOF
}

variable "domain_config" {
  type = object({
    auto_azure_dns_setup = bool
    dns_zones = optional(map(object({
      dns_zone            = string
      resource_group_name = optional(string)
    })))
  })
  default = null

  validation {
    condition     = try(!var.domain_config.auto_azure_dns_setup || var.domain_config.dns_zones != null, true)
    error_message = "If auto_azure_dns_setup is true, dns_zones must be set"
  }

  validation {
    condition     = try(var.domain_config.auto_azure_dns_setup || var.domain_config.dns_zones == null, true)
    error_message = "If auto_azure_dns_setup is false, dns_zones must not be set"
  }

  description = <<EOF
    Options for setting up domain names and DNS records.

    auto_azure_dns_setup: If true, AzureDNS will be automatically set up. dns_zones must be set if this is true. Otherwise, the custom domains, if desired, must be set manually.

    dns_zones: A map of components (or a default value) to their dns_zone zones. The valid keys are {default, langflow, assistants}. For each, dns_zone must be set, and resource_group_name may be set for further dns_zone filtering.
      dns_zone: The name (e.g. "example.com") of the existing DNS zone to use.
      resource_group_name: The resource group that the dns_zone is in. If not set, the first dns_zone matching the name will be used.
  EOF
}

variable "deployment_defaults" {
  type = object({
    min_instances   = optional(number)
    max_instances   = optional(number)
  })
  nullable = false
  default  = {}

  description = <<EOF
    Defaults for container app deployments. Some fields may be overridable on a per-component basis.

    min_instances: The minimum number of instances to run. Defaults to 1. Must be >= 1.

    max_instances: The maximum number of instances to run. Defaults to 20.
  EOF
}

variable "assistants" {
  type = object({
    subdomain = optional(string)
    containers = optional(object({
      env    = optional(map(string))
      cpu    = optional(number)
      memory = optional(string)
    }))
    deployment = optional(object({
      image_version = optional(string)
      min_instances = optional(number)
      max_instances = optional(number)
    }))
    astra_db = object({
      regions             = optional(set(string))
      deletion_protection = optional(bool)
      cloud_provider      = optional(string)
    })
  })
  default = null

  description = <<EOF
    Options for the Astra Assistant API service.

    subdomain: The subdomain to use for the service, if `domain_config.auto_azure_dns_setup` is true. Should be null if `domain_config.auto_azure_dns_setup` is false.

    containers:
      env: Environment variables to set for the service.
      cpu: The amount of CPU to allocate to the service. Defaults to 1024.
      memory: The amount of memory to allocate to the service. Defaults to 2048 (Mi).

    deployment:
      image_version: The image version to use for the deployment; defaults to "latest".
      min_instances: The minimum number of instances to run. Defaults to 1. Must be >= 1.
      max_instances: The maximum number of instances to run. Defaults to 20.

    astra_db: Options for the database Astra Assistants uses. Will be created even if this is not set.
      regions: The regions to deploy the database to. Defaults to the first available region.
      cloud_provider: The cloud provider to use for the database. Defaults to "azure".
      deletion_protection: The database can't be deleted when this value is set to true. The default is false.
  EOF
}

variable "langflow" {
  type = object({
    subdomain = optional(string)
    containers = optional(object({
      env    = optional(map(string))
      cpu    = optional(number)
      memory = optional(string)
    }))
    deployment = optional(object({
      image_version = optional(string)
      min_instances = optional(number)
      max_instances = optional(number)
    }))
    postgres_db = optional(object({
      sku_name    = string
      location    = optional(string)
      max_storage = optional(number)
    }))
  })
  default = null

  description = <<EOF
    Options for the Langflow service.

    subdomain: The subdomain to use for the service, if `domain_config.auto_azure_dns_setup` is true. Should be null if `domain_config.auto_azure_dns_setup` is false.

    containers:
      env: Environment variables to set for the service.
      cpu: The amount of CPU to allocate to the service. Defaults to 1.
      memory: The amount of memory to allocate to the service. Defaults to "2Gi".

    deployment:
      image_version: The image version to use for the deployment; defaults to "latest".
      min_instances: The minimum number of instances to run. Defaults to 1. Must be >= 1.
      max_instances: The maximum number of instances to run. Defaults to 20.

    postgres_db: Creates a basic Postgres instance to enable proper data persistence. Recommended to provide your own via the LANGFLOW_DATBASE_URL env var in production use cases. Will default to ephemeral SQLite instances if not set.
      sku_name: The SKU Name for the PostgreSQL Flexible Server. The name of the SKU follows the tier + name pattern (e.g. B_Standard_B1ms, GP_Standard_D2s_v3, MO_Standard_E4s_v3).
      max_storage: The max storage (in MB). Possible values are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216 and 33553408. Defaults to 32768 (MB).
      location: The Azure Region where the db instance should exist.
  EOF
}

variable "vector_dbs" {
  type = list(object({
    name                = string
    regions             = optional(set(string))
    keyspaces           = optional(list(string))
    cloud_provider      = optional(string)
    deletion_protection = optional(bool)
  }))
  nullable = false
  default  = []

  description = <<EOF
    Quickly sets up vector-enabled Astra Databases for your project.

    name: The name of the database to create.

    regions: The regions to deploy the database to. Defaults to the first available region.

    keyspaces: The keyspaces to use for the database. The first keyspace will be used as the initial one for the database. Defaults to just "default_keyspace".

    cloud_provider: The cloud provider to use for the database. Defaults to "azure".

    deletion_protection: The database can't be deleted when this value is set to true. The default is false.
  EOF
}
