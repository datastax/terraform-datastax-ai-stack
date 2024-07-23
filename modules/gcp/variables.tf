variable "project_config" {
  type = object({
    project_id = optional(string)
    create_project = optional(object({
      name            = optional(string)
      org_id          = optional(string)
      billing_account = string
    }))
  })
  default   = null
  sensitive = true

  validation {
    condition     = try(var.project_config.project_id != null && var.project_config.create_project == null || var.project_config.project_id == null && var.project_config.create_project != null, true)
    error_message = "Either project_id or create_project must be set"
  }

  description = <<EOF
    Sets the project to use for the deployment. If project_id is set, that project will be used. If create_project is set, a project will be created with a randomly generated ID and the given options. One of the two must be set.

    project_id: The ID of the project to use.

    create_project: Options to use when creating a new project.
      name: The name of the project to create. If not set, a random name will be generated.
      org_id: The ID of the organization to create the project in. 
      billing_account: The ID of the billing account to associate with the project.

    If further customization is desired, the project can be created manually and the project_id can be set. The Google "project-factory" module can be used to create a project with more options.
  EOF
}

variable "domain_config" {
  type = object({
    auto_cloud_dns_setup = bool
    managed_zones = optional(map(object({
      dns_name  = optional(string)
      zone_name = optional(string)
    })))
  })
  default = null

  validation {
    condition     = try(!var.domain_config.auto_cloud_dns_setup || var.domain_config.managed_zones != null, true)
    error_message = "If auto_cloud_dns_setup is true, managed_zones must be set"
  }

  validation {
    condition     = try(var.domain_config.auto_cloud_dns_setup || var.domain_config.managed_zones == null, true)
    error_message = "If auto_cloud_dns_setup is false, managed_zones must not be set"
  }

  validation {
    condition = try(
      var.domain_config.managed_zones == null || alltrue([
        for component, zone in coalesce(var.domain_config.managed_zones, {}) :
        (length(compact([zone.dns_name, zone.zone_name])) == 1)
      ]),
      true
    )
    error_message = "If managed_zones is set, (exactly) one of either dns_name or zone_name must be set"
  }

  description = <<EOF
    Options for setting up domain names and DNS records.

    auto_cloud_dns_setup: If true, Cloud DNS will be automatically set up. managed_zones must be set if this is true. If true, a name_servers map will be output; otherwise, you must set each domain to the output load_balancer_ip w/ an A record.

    managed_zones: A map of components (or a default value) to their managed zones. The valid keys are {default, langflow, assistants}. For each, either dns_name or zone_name must be set.
      dns_name: The DNS name (e.g. "example.com.") to use for the managed zone (which will be created).
      zone_name: The ID of the existing managed zone to use.
  EOF
}

variable "deployment_defaults" {
  type = object({
    min_instances = optional(number)
    max_instances = optional(number)
    location      = optional(string)
  })
  nullable = false
  default  = {}

  description = <<EOF
    Defaults for ECS deployments. Some fields may be overridable on a per-component basis.

    min_instances: The minimum number of instances to run. Defaults to 1. Must be >= 1.

    max_instances: The maximum number of instances to run. Defaults to 20.

    location: The location of the cloud run services.
  EOF
}

variable "assistants" {
  type = object({
    domain = optional(string)
    containers = optional(object({
      env    = optional(map(string))
      cpu    = optional(string)
      memory = optional(string)
    }))
    deployment = optional(object({
      image_version = optional(string)
      min_instances = optional(number)
      max_instances = optional(number)
      location      = optional(string)
    }))
    astra_db = optional(object({
      regions             = optional(set(string))
      deletion_protection = optional(bool)
      cloud_provider      = optional(string)
    }))
  })
  default = null

  description = <<EOF
    Options for the Astra Assistant API service.

    domain: The domain name to use for the service; used in the listener routing rules.

    containers:
      env: Environment variables to set for the service.
      cpu: The amount of CPU to allocate to the service. Defaults to "1".
      memory: The amount of memory to allocate to the service. Defaults to "2048Mi".

    deployment:
      image_version: The image version to use for the deployment; defaults to "latest".
      min_instances: The minimum number of instances to run. Defaults to 1. Must be >= 1.
      max_instances: The maximum number of instances to run. Defaults to 20.
      location: The location of the cloud run service.

    astra_db: Options for the database Astra Assistants uses. Will be created even if this is not set.
      regions: The regions to deploy the database to. Defaults to the first available region.
      cloud_provider: The cloud provider to use for the database. Defaults to "gcp".
      deletion_protection: The database can't be deleted when this value is set to true. The default is false.
  EOF
}

variable "langflow" {
  type = object({
    domain = optional(string)
    containers = optional(object({
      env    = optional(map(string))
      cpu    = optional(string)
      memory = optional(string)
    }))
    deployment = optional(object({
      image_version = optional(string)
      min_instances = optional(number)
      max_instances = optional(number)
      location      = optional(string)
    }))
    postgres_db = optional(object({
      tier                = string
      region              = optional(string)
      deletion_protection = optional(bool)
      initial_storage     = optional(number)
      max_storage         = optional(number)
    }))
  })
  default = null

  description = <<EOF
    Options for the Langflow service.

    domain: The domain name to use for the service; used in the listener routing rules.

    containers:
      env: Environment variables to set for the service.
      cpu: The amount of CPU to allocate to the service. Defaults to 1024.
      memory: The amount of memory to allocate to the service. Defaults to 2048 (Mi).

    deployment:
      image_version: The image version to use for the deployment; defaults to "latest".
      min_instances: The minimum number of instances to run. Defaults to 1. Must be >= 1.
      max_instances: The maximum number of instances to run. Defaults to 20.
      location: The location of the cloud run service.

    postgres_db: Creates a basic Postgres instance to enable proper data persistence. Recommended to provide your own via the LANGFLOW_DATBASE_URL env var in production use cases. Will default to ephemeral SQLite instances if not set.
      tier: The machine type to use. https://cloud.google.com/sql/docs/mysql/admin-api/rest/v1beta4/tiers
      region: The region for the db instance; defaults to the provider's region.
      deletion_protection: The database can't be deleted when this value is set to true. The default is false.
      initial_storage: The size of the data disk in GB. Must be >= 10GB.
      max_storage:  The maximum size to which the storage capacity can be autoscaled. The default value is 0, which specifies that there is no limit.
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

    cloud_provider: The cloud provider to use for the database. Defaults to "gcp".

    deletion_protection: The database can't be deleted when this value is set to true. The default is false.
  EOF
}
