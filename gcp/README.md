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
  source = "../gcp"

  project_config = {
    create_project = {
      billing_account = var.billing_account
    }
  }

  domain_config = {
    auto_cloud_dns_setup = true
    managed_zones = {
      default = { dns_name = "${var.domain}." }
    }
  }

  langflow = {
    domain = "langflow.${var.domain}"
    env = {
      LANGFLOW_DATABASE_URL = var.langflow_db_url
    }
  }

  assistants = {
    db = {
      regions             = ["us-east1"]
      deletion_protection = false
    }
  }

  vector_dbs = [
    {
      name      = "my_vector_db"
      keyspaces = ["my_keyspace1", "my_keyspace2"]
    }
  ]
}
```

## Required providers

| Name   | Version |
|--------|---------|
| astra  |         |
| google |         |

## Inputs

### `project_config` (required if using GCP-deployed components)

Options related to the project these deployments are tied to. If project_id is set, that project will be used. If create_project is set, a project will be created with the given options. One of the two must be set.

If further customization is desired, the project can be created manually and the project_id can be set. The Google "project-factory" module can be used to create a project with more options.

| Field          | Description | Type |
| -------------- | ----------- | ---- |
| project_id     | The ID of the project to use. | `optional(string)` | 
| create_project | Options to use when creating a new project.<br>- name: The name of the project to create. If not set, a random name will be generated.<br>- org_id: The ID of the organization to create the project in.<br>- billing_account: The ID of the billing account to associate with the project. | <pre>optional(object({<br>  name            = optional(string)<br>  org_id          = optional(string)<br>  billing_account = string<br>}))</pre> |

### `domain_config` (required if using GCP-deployed components)

Options related to DNS/HTTPS setup. If you create a managed zone on Cloud DNS, this module is able to handle the most of this for you.

Note that it may take a bit for the custom domain to properly work while the SSL cert is being set up.

| Field                | Description | Type |
| -------------------- | ----------- | ---- |
| auto_cloud_dns_setup | If true, Cloud DNS will be automatically set up. `managed_zones` must be set if this is true. If true, a `name_servers` map will be output, which you must add to your DNS records; otherwise, you must set each domain to the output `load_balancer_ip` w/ an A record. | `bool` |
| managed_zones        | A map of components (or a default value) to their managed zones. The valid keys are {default, langflow, assistants}. For each, either dns_name or zone_name must be set.<br>- dns_name: The DNS name (e.g. "example.com.") to use for the managed zone (which will be created).<br>- zone_name: The ID of the existing managed zone to use. | <pre>optional(map(object({<br>  dns_name  = optional(string)<br>  zone_name = optional(string)<br>})))</pre> |

### `cloud_run_config` (optional)

Sets global options for the Cloud Run services.

| Field    | Description                                                                                              | Type               |
| -------- | -------------------------------------------------------------------------------------------------------- | ------------------ |
| location | The location to deploy the Cloud Run services to. If not set, the first available location will be used. | `optional(string)` | 

### `langflow` (optional)

Options regarding the langflow deployment. If not set, langflow is not created. If no custom domain is set, the Cloud Run service's ingress will be set to "ALL" and expose a dedicated service URI.

| Field      | Description | Type |
| ---------- | ----------- | ---- |
| version    | The image version to use for the deployment; defaults to "latest". | `optional(string)` |
| domain     | The domain name to use for the service; used in the URL map. | `optional(string)` |
| env        | Environment variables to set for the service. | `optional(map(string))` |
| containers | Options for the ECS service.<br>- cpu: The amount of CPU to allocate to the service. Defaults to "1".<br>- memory: The amount of memory to allocate to the service. Defaults to "2048Mi".<br>- min_instances: The minimum number of instances to run. Defaults to 0.<br>- max_instances: The maximum number of instances to run. Defaults to 100. | <pre>optional(object({<br>  cpu           = optional(string)<br>  memory        = optional(string)<br>  min_instances = optional(number)<br>  max_instances = optional(number)<br>}))</pre> |

### `assistants` (optional)

Options regarding the astra-assistants-api deployment. If not set, assistants is not created. If no custom domain is set, the Cloud Run service's ingress will be set to "ALL" and expose a dedicated service URI.

| Field      | Description | Type |
| ---------- | ----------- | ---- |
| version    | The image version to use for the deployment; defaults to "latest". | `optional(string)` |
| domain     | The domain name to use for the service; used in the URL map. | `optional(string)` |
| env        | Environment variables to set for the service. | `optional(map(string))` |
| db         | Options for the database Astra Assistants uses.<br>- regions: The regions to deploy the database to. Defaults to the first available region.<br>- deletion_protection: Whether to enable deletion protection on the database.<br>- cloud_provider: The cloud provider to use for the database. Defaults to "gcp". | <pre>optional(object({<br>  regions             = optional(set(string))<br>  deletion_protection = optional(bool)<br>  cloud_provider      = optional(string)<br>}))</pre> |
| containers | Options for the ECS service.<br>- cpu: The amount of CPU to allocate to the service. Defaults to "1".<br>- memory: The amount of memory to allocate to the service. Defaults to "2048Mi".<br>- min_instances: The minimum number of instances to run. Defaults to 0.<br>- max_instances: The maximum number of instances to run. Defaults to 100. | <pre>optional(object({<br>  cpu           = optional(string)<br>  memory        = optional(string)<br>  min_instances = optional(number)<br>  max_instances = optional(number)<br>}))</pre> |

### `vector_dbs` optional

A list of configuration for each vector-enabled DB you may want to create/deploy. No custom domain is required to use this.

| Field                | Description                                                                    | Type                    |
| -------------------- | ------------------------------------------------------------------------------ | ----------------------- |
| name                 | The name of the database to create.                                            | `string`                |
| regions              | The regions to deploy the database to. Defaults to the first available region. | `optional(set(string))` |
| keyspaces            | The keyspaces to use for the database. The first keyspace will be used as the initial one for the database. Defaults to just "default_keyspace". | `optional(list(string))` |
| cloud_provider       | The cloud provider to use for the database. Defaults to "gcp".                 | `optional(string)`      |
| deletion_protection  | Whether to enable deletion protection on the database.                         | `optional(bool)`        |

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
