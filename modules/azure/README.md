# Datastax AI stack (Azure)

Terraform module which helps you quickly deploy an opinionated AI/RAG stack to Azure, provided by Datastax.

It offers multiple easy-to-deploy components, including:
 - Langflow
 - Astra Assistants API
 - Vector databases

## Prerequisites

You will, of course, need a valid Azure account, and have the `azurerm` provider set up.

You may want a custom domain to attach to the Langflow/Assistants services, but it is not required.

To allow the module to configure necessary any DNS/Custom Domain settings, you'll also need to have an Azure DNS zone set up; otherwise, you will manually have to register your custom domains.

## Basic usage

```hcl
module "datastax-ai-stack-azure" {
  source  = "datastax/ai-stack/astra//modules/azure"

  resource_group_config = {
    create_resource_group = {
      name     = "datastax-ai-stack"
      location = "East US"
    }
  }

  domain_config = {
    auto_azure_dns_setup = true
    dns_zones = {
      default = { dns_zone = var.dns_zone }
    }
  }

  langflow = {
    subdomain = "langflow"
    postgres_db = {
      sku_name            = "B_Standard_B1ms"
    }
  }

  assistants = {
    subdomain = "assistants"
    astra_db = {
      deletion_protection = false
    }
  }

  vector_dbs = [{
    name                = "my_db"
    keyspaces           = ["main_keyspace", "other_keyspace"]
    deletion_protection = false
  }]
}
```

## Required providers

| Name    | Version   |
|---------|-----------|
| astra   | >= 2.3.3  |
| azurerm | >= 3.79.0 |

## Inputs

### `resource_group_config` (required if not providing existing resource group)

Sets the resource group to use for the deployment. If `resource_group_name` is set, that group will be used. If `create_resource_group` is set, a group will be created with the given options. One of the two must be set.

| Field                  | Description | Type |
| ---------------------- | ----------- | ---- |
| resource_group_name    | The name of the resource group to use. | `optional(string)` |
| create_resource_group  | Options to use when creating a new resource group.<br>- name: The name of the resource group to create.<br>- location: The location to create the resource group in (e.g. "East US"). | <pre>optional(object({<br>  name     = string<br>  location = string<br>}))</pre> |

### `domain_config` (required if using DNS)

Options for setting up domain names and DNS records.

| Field                 | Description | Type |
| --------------------- | ----------- | ---- |
| auto_azure_dns_setup  | If `true`, AzureDNS will be automatically set up. `dns_zones` must be set if this is true. Otherwise, the custom domains, if desired, must be set manually. | `bool` |
| dns_zones             | A map of components (or a default value) to their DNS zones. The valid keys are {default, langflow, assistants}. For each, `dns_zone` must be set, and `resource_group_name` may be set for further DNS zone filtering.<br>- dns_zone: The name (e.g. "example.com") of the existing DNS zone to use.<br>- resource_group_name: The resource group that the DNS zone is in. If not set, the first DNS zone matching the name will be used. | <pre>optional(map(object({<br>  dns_zone            = string<br>  resource_group_name = optional(string)<br>})))</pre> |

### `deployment_defaults` (optional)

Defaults for ECS deployments. Some fields may be overridable on a per-component basis.

| Field                     | Description | Type |
| ------------------------- | ----------- | ---- |
| min_instances             | The minimum number of instances to run. Defaults to 1. Must be >= 1. | `optional(number)` |
| max_instances             | The maximum number of instances to run. Defaults to 20. | `optional(number)` |

### `assistants` (optional)

Options for the Astra Assistant API service.

| Field        | Description | Type |
| ------------ | ----------- | ---- |
| subdomain    | The subdomain to use for the service, if `domain_config.auto_azure_dns_setup` is true. Should be null if `domain_config.auto_azure_dns_setup` is false. | `optional(string)` |
| containers   | Environment variables to set for the service.<br>- cpu: The amount of CPU to allocate to the service. Defaults to 1024.<br>- memory: The amount of memory to allocate to the service. Defaults to "2048Mi". | <pre>optional(object({<br>  env    = optional(map(string))<br>  cpu    = optional(number)<br>  memory = optional(string)<br>}))</pre> |
| deployment   | Options for the deployment.<br>- image_version: The image version to use for the deployment; defaults to "latest".<br>- min_instances: The minimum number of instances to run. Defaults to 1. Must be >= 1.<br>- max_instances: The maximum number of instances to run. Defaults to 20. | <pre>optional(object({<br>  image_version = optional(string)<br>  min_instances = optional(number)<br>  max_instances = optional(number)<br>}))</pre> |
| astra_db     | Options for the database Astra Assistants uses. Will be created even if this is not set.<br>- regions: The regions to deploy the database to. Defaults to the first available region.<br>- cloud_provider: The cloud provider to use for the database. Defaults to "azure".<br>- deletion_protection: The database can't be deleted when this value is set to true. The default is false. | <pre>object({<br>  regions             = optional(set(string))<br>  deletion_protection = optional(bool)<br>  cloud_provider      = optional(string)<br>})</pre> |

### `langflow` (optional)

Options for the Langflow service.

| Field        | Description | Type |
| ------------ | ----------- | ---- |
| subdomain    | The subdomain to use for the service, if `domain_config.auto_azure_dns_setup` is true. Should be null if `domain_config.auto_azure_dns_setup` is false. | `optional(string)` |
| containers   | Environment variables to set for the service.<br>- cpu: The amount of CPU to allocate to the service. Defaults to 1.<br>- memory: The amount of memory to allocate to the service. Defaults to "2Gi". | <pre>optional(object({<br>  env    = optional(map(string))<br>  cpu    = optional(number)<br>  memory = optional(string)<br>}))</pre> |
| deployment   | Options for the deployment.<br>- image_version: The image version to use for the deployment; defaults to "latest".<br>- min_instances: The minimum number of instances to run. Defaults to 1. Must be >= 1.<br>- max_instances: The maximum number of instances to run. Defaults to 20. | <pre>optional(object({<br>  image_version = optional(string)<br>  min_instances = optional(number)<br>  max_instances = optional(number)<br>}))</pre> |
| postgres_db  | Creates a basic Postgres instance to enable proper data persistence. Recommended to provide your own via the LANGFLOW_DATBASE_URL env var in production use cases. Will default to ephemeral SQLite instances if not set.<br>- sku_name: The SKU Name for the PostgreSQL Flexible Server. The name of the SKU follows the tier + name pattern (e.g. B_Standard_B1ms, GP_Standard_D2s_v3, MO_Standard_E4s_v3).<br>- max_storage: The max storage (in MB). Possible values are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216 and 33553408. Defaults to 32768 (MB).<br>- location: The Azure Region where the db instance should exist. | <pre>optional(object({<br>  sku_name    = string<br>  location    = optional(string)<br>  max_storage = optional(number)<br>}))</pre> |

### `vector_dbs` (optional)

Quickly sets up vector-enabled Astra Databases for your project.

| Field               | Description | Type |
| ------------------- | ----------- | ---- |
| name                | The name of the database to create. | `string` |
| regions             | The regions to deploy the database to. Defaults to the first available region. | `optional(set(string))` |
| keyspaces           | The keyspaces to use for the database. The first keyspace will be used as the initial one for the database. Defaults to just "default_keyspace". | `optional(list(string))` |
| cloud_provider      | The cloud provider to use for the database. Defaults to "azure". | `optional(string)` |
| deletion_protection | The database can't be deleted when this value is set to true. The default is false. | `optional(bool)` |

## Outputs

### `langflow_fqdn` (`string`)

The fully-qualified domain name of the created langflow service (if it exists)

### `assistants_fqdn` (`string`)

The fully-qualified domain name of the created astra-assistants-api service (if it exists)

### `db_ids` (`map(string)`)

A map of DB IDs => DB names for all of the dbs created (from the `assistants` module and the `vector_dbs` module), e.g:

```hcl
"db_ids" = {
  "12345678-abcd-efgh-1234-abcd1234efgh" = "assistant_api_db"
}
```
