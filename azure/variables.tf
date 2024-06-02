variable "assistants" {
  type = object({
    env    = optional(map(string))
    db     = optional(object({
      regions             = optional(set(string))
      deletion_protection = optional(bool)
      cloud_provider      = optional(string)
    }))
    containers = optional(object({
      cpu           = optional(number)
      memory        = optional(number)
      min_instances = optional(number)
      max_instances = optional(number)
    }))
  })
  default = null

  description = <<EOF
    Options for the Astra Assistant API service.

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
    env        = optional(map(string))
    containers = optional(object({
      cpu           = optional(number)
      memory        = optional(number)
      min_instances = optional(number)
      max_instances = optional(number)
    }))
  })
  default = null

  description = <<EOF
    Options for the Langflow service.

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
