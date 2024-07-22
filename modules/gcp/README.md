# Datastax AI stack (GCP)

Terraform module which helps you quickly deploy an opinionated AI/RAG stack to GCP, provided by Datastax.

It offers multiple easy-to-deploy components, including:
 - Langflow
 - Astra Assistants API
 - Vector databases

## Prerequisites

You will, of course, need a valid GCP account, and have the `google` provider set up.

You may want a custom domain to attach to the Langflow/Assistants services, but it is not required.

## Basic usage

```hcl
module "datastax-ai-stack-gcp" {
  source  = "datastax/ai-stack/astra//modules/gcp"

  project_config = {
    create_project = {
      billing_account = var.billing_account
    }
  }

  domain_config = {
    auto_cloud_dns_setup = true
    managed_zones = {
      default = { dns_name = "${var.dns_name}." }
    }
  }

  langflow = {
    domain = "langflow.${var.dns_name}"
    postgres_db = {
      tier                = "db-f1-micro"
      deletion_protection = false
    }
  }

  assistants = {
    domain = "assistants.${var.dns_name}"
    astra_db = {
      deletion_protection = false
    }
  }

  vector_dbs = [{
    name      = "my_db"
    keyspaces = ["main_keyspace", "other_keyspace"]
    deletion_protection = false
  }]
}
```

## Required providers

| Name   | Version   |
|--------|-----------|
| astra  | >= 2.3.3  |
| google | >= 5.12.0 |

## Inputs

### `project_config` (required)

Sets the project to use for the deployment. If `project_id` is set, that project will be used. If `create_project` is set, a project will be created with a randomly generated ID and the given options. One of the two must be set.

| Field             | Description | Type |
| ----------------- | ----------- | ---- |
| project_id        | The ID of the project to use. | `optional(string)` |
| create_project    | Options to use when creating a new project.<br>- name: The name of the project to create. If not set, a random name will be generated.<br>- org_id: The ID of the organization to create the project in.<br>- billing_account: The ID of the billing account to associate with the project. | <pre>optional(object({<br>  name            = optional(string)<br>  org_id          = optional(string)<br>  billing_account = string<br>}))</pre> |

### `domain_config` (required if using DNS)

Options for setting up domain names and DNS records.

| Field                  | Description | Type |
| ---------------------- | ----------- | ---- |
| auto_cloud_dns_setup   | If `true`, Cloud DNS will be automatically set up. `managed_zones` must be set if this is true. If true, a `name_servers` map will be output; otherwise, you must set each domain to the output `load_balancer_ip` w/ an A record. | `bool` |
| managed_zones          | A map of components (or a default value) to their managed zones. The valid keys are {default, langflow, assistants}. For each, either `dns_name` or `zone_name` must be set.<br>- dns_name: The DNS name (e.g. "example.com.") to use for the managed zone (which will be created).<br>- zone_name: The ID of the existing managed zone to use. | <pre>optional(map(object({<br>  dns_name  = optional(string)<br>  zone_name = optional(string)<br>})))</pre> |

### `deployment_defaults` (optional)

Defaults for ECS deployments. Some fields may be overridable on a per-component basis.

| Field           | Description | Type |
| --------------- | ----------- | ---- |
| min_instances   | The minimum number of instances to run. Defaults to 1. Must be >= 1. | `optional(number)` |
| max_instances   | The maximum number of instances to run. Defaults to 20. | `optional(number)` |
| location        | The location of the cloud run services. | `optional(string)` |

### `assistants` (optional)

Options for the Astra Assistant API service.

| Field        | Description | Type |
| ------------ | ----------- | ---- |
| domain       | The domain name to use for the service; used in the listener routing rules. | `optional(string)` |
| containers   | Environment variables to set for the service.<br>- cpu: The amount of CPU to allocate to the service. Defaults to "1".<br>- memory: The amount of memory to allocate to the service. Defaults to "2048Mi". | <pre>optional(object({<br>  env    = optional(map(string))<br>  cpu    = optional(string)<br>  memory = optional(string)<br>}))</pre> |
| deployment   | Options for the deployment.<br>- image_version: The image version to use for the deployment; defaults to "latest".<br>- min_instances: The minimum number of instances to run. Defaults to 1. Must be >= 1.<br>- max_instances: The maximum number of instances to run. Defaults to 20.<br>- location: The location of the cloud run service. | <pre>optional(object({<br>  image_version   = optional(string)<br>  min_instances   = optional(number)<br>  max_instances   = optional(number)<br>  location        = optional(string)<br>}))</pre> |
| astra_db     | Options for the database Astra Assistants uses. Will be created even if this is not set.<br>- regions: The regions to deploy the database to. Defaults to the first available region.<br>- cloud_provider: The cloud provider to use for the database. Defaults to "gcp".<br>- deletion_protection: The database can't be deleted when this value is set to true. The default is false. | <pre>optional(object({<br>  regions             = optional(set(string))<br>  deletion_protection = optional(bool)<br>  cloud_provider      = optional(string)<br>}))</pre> |

### `langflow` (optional)

Options for the Langflow service.

| Field        | Description | Type |
| ------------ | ----------- | ---- |
| domain       | The domain name to use for the service; used in the listener routing rules. | `optional(string)` |
| containers   | Environment variables to set for the service.<br>- cpu: The amount of CPU to allocate to the service. Defaults to 1024.<br>- memory: The amount of memory to allocate to the service. Defaults to 2048 (Mi). | <pre>optional(object({<br>  env    = optional(map(string))<br>  cpu    = optional(string)<br>  memory = optional(string)<br>}))</pre> |
| deployment   | Options for the deployment.<br>- image_version: The image version to use for the deployment; defaults to "latest".<br>- min_instances: The minimum number of instances to run. Defaults to 1. Must be >= 1.<br>- max_instances: The maximum number of instances to run. Defaults to 20.<br>- location: The location of the cloud run service. | <pre>optional(object({<br>  image_version   = optional(string)<br>  min_instances   = optional(number)<br>  max_instances   = optional(number)<br>  location        = optional(string)<br>}))</pre> |
| postgres_db  | Creates a basic Postgres instance to enable proper data persistence. Recommended to provide your own via the LANGFLOW_DATBASE_URL env var in production use cases. Will default to ephemeral SQLite instances if not set.<br>- tier: The machine type to use. https://cloud.google.com/sql/docs/mysql/admin-api/rest/v1beta4/tiers<br>- region: The region for the db instance; defaults to the provider's region.<br>- deletion_protection: The database can't be deleted when this value is set to true. The default is false.<br>- initial_storage: The size of the data disk in GB. Must be >= 10GB.<br>- max_storage: The maximum size to which the storage capacity can be autoscaled. The default value is 0, which specifies that there is no limit. | <pre>optional(object({<br>  tier                = string<br>  region              = optional(string)<br>  deletion_protection = optional(bool)<br>  initial_storage     = optional(number)<br>  max_storage         = optional(number)<br>}))</pre> |

### `vector_dbs` (optional)

Quickly sets up vector-enabled Astra Databases for your project.

| Field               | Description | Type |
| ------------------- | ----------- | ---- |
| name                | The name of the database to create. | `string` |
| regions             | The regions to deploy the database to. Defaults to the first available region. | `optional(set(string))` |
| keyspaces           | The keyspaces to use for the database. The first keyspace will be used as the initial one for the database. Defaults to just "default_keyspace". | `optional(list(string))` |
| cloud_provider      | The cloud provider to use for the database. Defaults to "gcp". | `optional(string)` |
| deletion_protection | The database can't be deleted when this value is set to true. The default is false. | `optional(bool)` |

## Outputs

### `load_balancer_ip` (`string`)

The IP address of the created ELB through which to access the Cloud Run services w/ a custom domain

### `project_id` (`string`)

The ID of the created project (or regurgitated if an existing one was used)

### `nameservers` (`map(list(string))`)

The nameservers that need to be set for any created managed zones, e.g:

```hcl
"name_servers" = {
  "gcp.example.com." = tolist([
    "ns-cloud-c1.googledomains.com.",
    "ns-cloud-c2.googledomains.com.",
    "ns-cloud-c3.googledomains.com.",
    "ns-cloud-c4.googledomains.com.",
  ])
}
```

### `service_uris` (`map(string)`)

The map of the services to the URLs you would use to access them, e.g.:

```hcl
"service_uris" = {
  "assistants" = "https://astra-assistants-service-abcdefghij-kl.a.run.app"
  "langflow" = "https://langflow.gcp.example.com"
}
```

### `db_ids` (`map(string)`)

A map of DB IDs => DB names for all of the dbs created (from the `assistants` module and the `vector_dbs` module), e.g:

```hcl
"db_ids" = {
  "12345678-abcd-efgh-1234-abcd1234efgh" = "assistant_api_db"
}
```
