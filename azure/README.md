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
module "enterprise-gpts-azure" {
  source = "../azure"

  resource_group_config = {
    create_resource_group = {
      name     = "enterprise-ai-stack"
      location = "East US"
    }
  }

  domain_config = {
    auto_azure_dns_setup = true
    dns_zones = {
      default = { dns_zone = "az.enterprise-ai-stack.com" }
    }
  }

  langflow = {
    subdomain = "langflow"
    env = {
      LANGFLOW_DATABASE_URL = var.langflow_db_url
    }
  }

  assistants = {
    subdomain = ""
    db = {
      deletion_protection = false
    }
  }
}
```

## Required providers

| Name    | Version |
|---------|---------|
| astra   |         |
| azurerm |         |

## Inputs

### `resource_group_config` (required)

Sets the resource group to use for the deployment. If resource_group_name is set, that group will be used. If create_resource_group is set, a group will be created with the given options. One of the two must be set.

If further customization is desired, the resource group can be created manually and the resource_group_name can be set.

| Field                 | Description | Type |
| --------------------- | ----------- | ---- |
| resource_group_name   | The name of the resource group to use. | `optional(string)` | 
| create_resource_group | Options to use when creating a new resource group.<br>- name: The name of the resource group to create.<br>- location: The location to create the resource group in (e.g. "East US"). | <pre>optional(object({<br>  name     = string<br>  location = string<br>}))</pre> |

### `domain_config` (required)

Options related to DNS/HTTPS setup. If you create a DNS zone on Azure DNS, this module is able to handle the most of this for you.

| Field                | Description | Type |
| -------------------- | ----------- | ---- |
| auto_azure_dns_setup | If true, AzureDNS will be automatically set up. dns_zones must be set if this is true. Otherwise, the custom domains, if desired, must be set manually. | `bool` |
| dns_zones            | A map of components (or a default value) to their dns_zone zones. The valid keys are {default, langflow, assistants}. For each, dns_zone must be set, and resource_group_name may be set for further dns_zone filtering.<br>- dns_zone: The name (e.g. "example.com") of the existing DNS zone to use.<br>- resource_group_name: The resource group that the dns_zone is in. If not set, the first dns_zone matching the name will be used. | <pre>optional(map(object({<br>  dns_zone            = string<br>  resource_group_name = optional(string)<br>})))</pre> |

### `langflow` (optional)

Options regarding the langflow deployment. If not set, langflow is not created. If no custom domain is set, the Cloud Run service's ingress will be set to "ALL" and expose a dedicated service URI.

| Field      | Description | Type |
| ---------- | ----------- | ---- |
| subdomain  | The subdomain to use for the service, if `domain_config.auto_azure_dns_setup` is true. Should be null if `domain_config.auto_azure_dns_setup` is false. | `optional(string)` |
| env        | Environment variables to set for the service. | `optional(map(string))` |
| containers | Options for the ECS service.<br>- cpu: The amount of CPU to allocate to the service. Defaults to 1.<br>- memory: The amount of memory to allocate to the service. Defaults to "2048Mi".<br>- min_instances: The minimum number of instances to run. Defaults to 0.<br>- max_instances: The maximum number of instances to run. Defaults to 100. | <pre>optional(object({<br>  cpu           = optional(number)<br>  memory        = optional(string)<br>  min_instances = optional(number)<br>  max_instances = optional(number)<br>}))</pre> |

### `assistants` (optional)

Options regarding the astra-assistants-api deployment. If not set, assistants is not created. If no custom domain is set, the Cloud Run service's ingress will be set to "ALL" and expose a dedicated service URI.

| Field      | Description | Type |
| ---------- | ----------- | ---- |
| subdomain  | The subdomain to use for the service, if `domain_config.auto_azure_dns_setup` is true. Should be null if `domain_config.auto_azure_dns_setup` is false. | `optional(string)` |
| env        | Environment variables to set for the service. | `optional(map(string))` |
| db         | Options for the database Astra Assistants uses.<br>- regions: The regions to deploy the database to. Defaults to the first available region.<br>- deletion_protection: Whether to enable deletion protection on the database.<br>- cloud_provider: The cloud provider to use for the database. Defaults to "gcp". | <pre>optional(object({<br>  regions             = optional(set(string))<br>  deletion_protection = optional(bool)<br>  cloud_provider      = optional(string)<br>}))</pre> |
| containers | Options for the ECS service.<br>- cpu: The amount of CPU to allocate to the service. Defaults to 1.<br>- memory: The amount of memory to allocate to the service. Defaults to "2048Mi".<br>- min_instances: The minimum number of instances to run. Defaults to 0.<br>- max_instances: The maximum number of instances to run. Defaults to 100. | <pre>optional(object({<br>  cpu           = optional(number)<br>  memory        = optional(string)<br>  min_instances = optional(number)<br>  max_instances = optional(number)<br>}))</pre> |

### `vector_dbs` optional

A list of configuration for each vector-enabled DB you may want to create/deploy. No custom domain is required to use this.

| Field                | Description                                                                    | Type                    |
| -------------------- | ------------------------------------------------------------------------------ | ----------------------- |
| name                 | The name of the database to create.                                            | `string`                |
| regions              | The regions to deploy the database to. Defaults to the first available region. | `optional(set(string))` |
| keyspace             | The keyspace to use for the database. Defaults to "default_keyspace".          | `optional(string)`      |
| cloud_provider       | The cloud provider to use for the database. Defaults to "azure".               | `optional(string)`      |
| deletion_protection  | Whether to enable deletion protection on the database.                         | `optional(bool)`        |

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
