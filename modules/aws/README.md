# Datastax AI stack (AWS)

Terraform module which helps you quickly deploy an opinionated AI/RAG stack to AWS, provided by Datastax.

It offers multiple easy-to-deploy components, including:
 - Langflow
 - Astra Assistants API
 - Vector databases

## Prerequisites

You will, of course, need a valid AWS account, and have the `aws` provider set up.

A custom domain is heavily recommended, but not necessary. If any service (e.g. Langflow or Astra Assistants API) is not
given a domain, an additional ALB will have to be constructed to serve solely that service. Further, it'll be served
over insecure http (if using langflow, you may need to apply [this](https://github.com/langflow-ai/langflow/issues/1508)
issue workaround)

To allow the module to configure necessary any DNS settings, you'll also need to have an AWS hosted zone set up;
otherwise, your domains will have to be manually configured to point to the `alb_dns_name`, and an acm cert arn will
have to manually be provided.

## Basic usage

```hcl
module "datastax-ai-stack-aws" {
  source = "datastax/ai-stack/astra//modules/aws"

  domain_config = {
    auto_route53_setup = true
    hosted_zones = {
      default = { zone_name = var.dns_zone_name }
    }
  }

  langflow = {
    domain = "langflow.${var.dns_zone_name}"
    postgres_db = {
      instance_class      = "db.t3.micro"
      deletion_protection = false
    }
  }

  assistants = {
    domain = "assistants.${var.dns_zone_name}"
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

| Name  | Version  |
|-------|----------|
| astra | >= 2.3.3 |
| aws   | >= 5.0.0 |

## Inputs

### `infrastructure` (optional)

Options related to the VPC/infrastructure. If not provided, a new VPC will be created for you.

| Field           | Description                                                  | Type           |
| --------------- | ------------------------------------------------------------ | -------------- |
| vpc_id          | The ID of the VPC to create the ALB and other components in. | `string`       | 
| public_subnets  | A list of public subnet IDs to create the ALB in.            | `list(string)` | 
| private_subnets | A list of private subnet IDs to create the ECS instances in. | `list(string)` | 
| security_groups | A list of security group IDs to attach to the ALB.           | `list(string)` | 

### `domain_config` (required if using ECS-deployed components)

Options related to DNS/HTTPS setup. If you create a hosted zone on Route53, this module is able to handle the most of this for you.

Regardless of whether `auto_route53_setup` is true or not though, a custom domain *is* required for some of the services.

| Field              | Description | Type |
| ------------------ | ----------- | ---- |
| auto_route53_setup | If `true`, Route53 will be automatically set up. `hosted_zones` must be set if this is true.<br><br>Otherwise, you must set each domain to the output `alb_dns_name` w/ an A record. | `bool` |
| hosted_zones       | A map of components (or a default value) to their hosted zones. The valid keys are {default, langflow, assistants}. For each, either `zone_id` or `zone_name` must be set. | <pre>optional(map(object({<br>  zone_id = optional(string)<br>  zone_name = optional(string)<br>})))</pre> |
| acm_cert_arn       | The ARN of the ACM certificate to use. Required if auto_route53_setup is `false`. If auto_route53_setup is `true`, you may choose to set this; otherwise, one is manually created. | `optional(string)` |

### `deployment_defaults` (optional)

Defaults for ECS deployments. Some fields may be overridable on a per-component basis.

| Field                     | Description | Type |
| ------------------------- | ----------- | ---- |
| vpc_availability_zones    | Availability zones to be used if the VPC is auto-created by this module. Will not do anything if your own VPC is provided. | `optional(list(string))` |
| capacity_provider_weights | The weights to assign to the capacity providers. If not set, it's a 20/80 split between Fargate and Fargate Spot.<br>  default_base: The base number of tasks to run on Fargate.<br>  default_weight: The relative weight for Fargate when scaling tasks.<br>  spot_base: The base number of tasks to run on Fargate Spot.<br>  spot_weight: The relative weight for Fargate Spot when scaling tasks. | <pre>optional(object({<br>  default_base  = number<br>  default_weight = number<br>  spot_base  = number<br>  spot_weight = number<br>}))</pre> |
| min_instances             | The minimum number of instances to run. Defaults to 1. Must be >= 1. | `optional(number)` |
| max_instances             | The maximum number of instances to run. Defaults to 20. | `optional(number)` |

### `assistants` (optional)

Options for the Astra Assistant API service.

| Field        | Description | Type |
| ------------ | ----------- | ---- |
| domain       | The domain name to use for the service; used in the listener routing rules. | `optional(string)` |
| containers   | Environment variables to set for the service.<br>- cpu: The amount of CPU to allocate to the service. Defaults to 1024.<br>- memory: The amount of memory to allocate to the service. Defaults to 2048 (Mi). | <pre>optional(object({<br>  env    = optional(map(string))<br>  cpu    = optional(number)<br>  memory = optional(number)<br>}))</pre> |
| deployment   | Options for the deployment.<br>- image_version: The image version to use for the deployment; defaults to "latest".<br>- min_instances: The minimum number of instances to run. Defaults to 1. Must be >= 1.<br>- max_instances: The maximum number of instances to run. Defaults to 20. | <pre>optional(object({<br>  image_version = optional(string)<br>  min_instances = optional(number)<br>  max_instances = optional(number)<br>}))</pre> |
| astra_db     | Options for the database Astra Assistants uses.<br>- regions: The regions to deploy the database to. Defaults to the first available region.<br>- cloud_provider: The cloud provider to use for the database. Defaults to "aws".<br>- deletion_protection: The database can't be deleted when this value is set to true. The default is false. | <pre>optional(object({<br>  regions             = optional(set(string))<br>  deletion_protection = optional(bool)<br>  cloud_provider      = optional(string)<br>}))</pre> |

### `langflow` (optional)

Options for the Langflow service.

| Field        | Description | Type |
| ------------ | ----------- | ---- |
| domain       | The domain name to use for the service; used in the listener routing rules. | `optional(string)` |
| containers   | Environment variables to set for the service.<br>- cpu: The amount of CPU to allocate to the service. Defaults to 1024.<br>- memory: The amount of memory to allocate to the service. Defaults to 2048 (Mi). | <pre>optional(object({<br>  env    = optional(map(string))<br>  cpu    = optional(number)<br>  memory = optional(number)<br>}))</pre> |
| deployment   | Options for the deployment.<br>- image_version: The image version to use for the deployment; defaults to "latest".<br>- min_instances: The minimum number of instances to run. Defaults to 1. Must be >= 1.<br>- max_instances: The maximum number of instances to run. Defaults to 20. | <pre>optional(object({<br>  image_version = optional(string)<br>  min_instances = optional(number)<br>  max_instances = optional(number)<br>}))</pre> |
| postgres_db  | Creates a basic Postgres instance to enable proper data persistence. Recommended to provide your own via the LANGFLOW_DATBASE_URL env var in production use cases. Will default to ephemeral SQLite instances if not set.<br>- instance_class: Determines the computation and memory capacity of an Amazon RDS DB instance.<br>- availability_zone: The AZ for the RDS instance.<br>- deletion_protection: The database can't be deleted when this value is set to true. The default is false.<br>- initial_storage: The allocated storage in GiB. If max_storage is set, this argument represents the initial storage allocation, enabling storage autoscaling.<br>- max_storage: When configured, the upper limit to which Amazon RDS can automatically scale the storage of the DB instance. | <pre>optional(object({<br>  instance_class      = string<br>  availability_zone   = optional(string)<br>  deletion_protection = optional(bool)<br>  initial_storage     = optional(number)<br>  max_storage         = optional(number)<br>}))</pre> |

### `vector_dbs` (optional)

Quickly sets up vector-enabled Astra Databases for your project.

| Field               | Description | Type |
| ------------------- | ----------- | ---- |
| name                | The name of the database to create. | `string` |
| regions             | The regions to deploy the database to. Defaults to the first available region. | `optional(set(string))` |
| keyspaces           | The keyspaces to use for the database. The first keyspace will be used as the initial one for the database. Defaults to just "default_keyspace". | `optional(list(string))` |
| cloud_provider      | The cloud provider to use for the database. Defaults to "aws". | `optional(string)` |
| deletion_protection | The database can't be deleted when this value is set to true. The default is false. | `optional(bool)` |

## Outputs

### `vpc_id` (`string`)

The ID of the VPC used. If created, it's the new ID; if set, it regurgitates the set ID.

### `alb_dns_name` (`string`)

The DNS name of the created ALB that the domains for langflow & assistants must be set to.

### `db_ids` (`map(string)`)

A map of DB IDs => DB names for all of the dbs created (from the `assistants` module and the `vector_dbs` module), e.g:

```hcl
"db_ids" = {
  "12345678-abcd-efgh-1234-abcd1234efgh" = "assistant_api_db"
}
```
