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
    managed_db = object({
      regions             = optional(set(string))
      deletion_protection = optional(bool)
      cloud_provider      = optional(string)
    })
  })
  default = null

  description = <<EOF
    Options for the Astra Assistant API service.

    version: The image version to use for the deployment; defaults to "latest".

    subdomain: The subdomain to use for the service, if `domain_config.auto_azure_dns_setup` is true. Should be null if `domain_config.auto_azure_dns_setup` is false.

    env: Environment variables to set for the service.

    db: Options for the database Astra Assistants uses.
      regions: The regions to deploy the database to. Defaults to the first available region.
      deletion_protection: Whether to enable deletion protection on the database.
      cloud_provider: The cloud provider to use for the database. Defaults to "azure".

    containers: Options for the Cloud Run service.
      cpu: The amount of CPU to allocate to the service. Defaults to 1.
      memory: The amount of memory to allocate to the service. Defaults to 2Gi.
      min_instances: The minimum number of instances to run. Defaults to 0.
      max_instances: The maximum number of instances to run. Defaults to 100.
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
    managed_db = optional(object({
      sku_name    = string
      location    = optional(string)
      max_storage = optional(number)
    }))
  })
  default = null

  description = <<EOF
    Options for the Langflow service.

    version: The image version to use for the deployment; defaults to "latest".

    subdomain: The subdomain to use for the service, if `domain_config.auto_azure_dns_setup` is true. Should be null if `domain_config.auto_azure_dns_setup` is false.

    env: Environment variables to set for the service.

    containers: Options for the Cloud Run service.
      cpu: The amount of CPU to allocate to the service. Defaults to 1.
      memory: The amount of memory to allocate to the service. Defaults to 2Gi.
      min_instances: The minimum number of instances to run. Defaults to 0.
      max_instances: The maximum number of instances to run. Defaults to 100.
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

    deletion_protection: Whether to enable deletion protection on the database. Defaults to true.
  EOF
}
