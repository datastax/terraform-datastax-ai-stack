variable "project_config" {
  type = object({
    project_id = optional(string)
    create_project = optional(object({
      name            = optional(string)
      org_id          = optional(string)
      billing_account = string
    }))
  })
  nullable  = false
  sensitive = true

  validation {
    condition     = var.project_config.project_id != null && var.project_config.create_project == null || var.project_config.project_id == null && var.project_config.create_project != null
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

variable "cloud_run_config" {
  type = object({
    location = optional(string)
  })
  default = null

  description = <<EOF
    Sets global options for the Cloud Run services.

    location: The location to deploy the Cloud Run services to. If not set, the first available location will be used.
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
  nullable = false

  validation {
    condition     = !var.domain_config.auto_cloud_dns_setup || var.domain_config.managed_zones != null
    error_message = "If auto_cloud_dns_setup is true, managed_zones must be set"
  }

  validation {
    condition     = var.domain_config.auto_cloud_dns_setup || var.domain_config.managed_zones == null
    error_message = "If auto_cloud_dns_setup is false, managed_zones must not be set"
  }

  validation {
    condition = var.domain_config.managed_zones == null || alltrue([
      for component, zone in coalesce(var.domain_config.managed_zones, {}) :
      (length(compact([zone.dns_name, zone.zone_name])) == 1)
    ])
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

variable "assistants" {
  type = object({
    version = optional(string)
    domain  = optional(string)
    env     = optional(map(string))
    db = optional(object({
      regions             = optional(set(string))
      deletion_protection = optional(bool)
      cloud_provider      = optional(string)
    }))
    containers = optional(object({
      cpu           = optional(string)
      memory        = optional(string)
      min_instances = optional(number)
      max_instances = optional(number)
    }))
  })
  default = null

  description = <<EOF
    Options for the Astra Assistant API service.

    version: The image version to use for the deployment; defaults to "latest".

    domain: The domain name to use for the service; used in the URL mapping.

    env: Environment variables to set for the service.

    db: Options for the database Astra Assistants uses.
      regions: The regions to deploy the database to. Defaults to the first available region.
      deletion_protection: Whether to enable deletion protection on the database.
      cloud_provider: The cloud provider to use for the database. Defaults to "gcp".

    containers: Options for the Cloud Run service.
      cpu: The amount of CPU to allocate to the service. Defaults to 1.
      memory: The amount of memory to allocate to the service. Defaults to 2048Mi.
      min_instances: The minimum number of instances to run. Defaults to 0.
      max_instances: The maximum number of instances to run. Defaults to 100.
  EOF
}

variable "langflow" {
  type = object({
    version = optional(string)
    domain  = optional(string)
    env     = optional(map(string))
    containers = optional(object({
      cpu           = optional(string)
      memory        = optional(string)
      min_instances = optional(number)
      max_instances = optional(number)
    }))
  })
  default = null

  description = <<EOF
    Options for the Langflow service.

    version: The image version to use for the deployment; defaults to "latest".

    domain: The domain name to use for the service; used in the URL mapping. 

    env: Environment variables to set for the service.

    containers: Options for the Cloud Run service.
      cpu: The amount of CPU to allocate to the service. Defaults to 1.
      memory: The amount of memory to allocate to the service. Defaults to 2048Mi.
      min_instances: The minimum number of instances to run. Defaults to 0.
      max_instances: The maximum number of instances to run. Defaults to 100.
  EOF
}

variable "vector_dbs" {
  type = list(object({
    name                = string
    regions             = optional(set(string))
    keyspace            = optional(string)
    cloud_provider      = optional(string)
    deletion_protection = optional(bool)
  }))
  nullable = false
  default  = []

  description = <<EOF
    Quickly sets up vector-enabled Astra Databases for your project.

    name: The name of the database to create.

    regions: The regions to deploy the database to. Defaults to the first available region.

    keyspace: The keyspace to use for the database. Defaults to "default_keyspace".

    cloud_provider: The cloud provider to use for the database. Defaults to "gcp".

    deletion_protection: Whether to enable deletion protection on the database.
  EOF
}
