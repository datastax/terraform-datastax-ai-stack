# Datastax AI stack (AWS)

Terraform module which helps you quickly deploy an opinionated AI/RAG stack to AWS, provided by Datastax.

It offers multiple easy-to-deploy components, including:
 - Langflow
 - Astra Assistants API
 - Vector databases

## Prerequisites

You will, of course, need a valid AWS account, and have the `aws` provider set up.

If using Langflow or Astra Assistants, you'll need a domain at hand to access those services.

To allow the module to configure necessary any DNS settings, you'll also need to have an AWS hosted zone set up; otherwise, your domains will have to be manually configured to point to the `alb_dns_name`.

## Basic usage

```hcl
module "enterprise-gpts-aws" {
  source = "../aws"

  domain_config = {
    auto_route53_setup = true
    hosted_zones = {
      default = { zone_name = var.domain }
    }
  }

  langflow = {
    domain = "langflow.${var.domain}"
    env = {
      LANGFLOW_DATABASE_URL = var.langflow_db_url
    }
  }

  assistants = {
    domain = "assistants.${var.domain}"
    db = {
      deletion_protection = false
    }
  }

  vector_dbs = [
    {
      name     = "my_vector_db"
      keyspace = "my_keyspace"
    }
  ]
}
```

## Required providers

| Name  | Version |
|-------|---------|
| astra |         |
| aws   |         |

## Inputs

### `infrastructure` (optional)

Options related to the VPC/infrastructure. If not provided, a new VPC will be created for you.

| Field           | Description                                                  | Type           |
| --------------- | ------------------------------------------------------------ | -------------- |
| vpc_id          | The ID of the VPC to create the ALB and other components in. | `string`       | 
| public_subnets  | A list of public subnet IDs to create the ALB in.            | `list(string)` | 
| private_subnets | A list of private subnet IDs to create the ECS instances in. | `list(string)` | 
| security_groups | A list of security group IDs to attach to the ALB.           | `list(string)` | 

### `domain_config` (required)

Options related to DNS/HTTPS setup. If you create a hosted zone on Route53, this module is able to handle the most of this for you.

Regardless of whether `auto_route53_setup` is true or not though, a custom domain *is* required for some of the services.

| Field              | Description | Type |
| ------------------ | ----------- | ---- |
| auto_route53_setup | If `true`, Route53 will be automatically set up. `hosted_zones` must be set if this is true.<br><br>Otherwise, you must set each domain to the output `alb_dns_name` w/ an A record. | `bool` |
| hosted_zones       | A map of components (or a default value) to their hosted zones. The valid keys are {default, langflow, assistants}. For each, either `zone_id` or `zone_name` must be set. | <pre>optional(map(object({<br>  zone_id = optional(string)<br>  zone_name = optional(string)<br>})))</pre> |
| acm_cert_arn       | The ARN of the ACM certificate to use. Required if auto_route53_setup is `false`. If auto_route53_setup is `true`, you may choose to set this; otherwise, one is manually created. | `optional(boolean)` |

### `fargate_config` (optional)

Options related to the deployment of the ECS on Fargate instances.

| Field                     | Description | Type |
| ------------------------- | ----------- | ---- |
| capacity_provider_weights | The weights to assign to the capacity providers.<br>If not set, it's a 20/80 split between Fargate and Fargate Spot.| <pre>optional(object({<br>  default_base  = number<br>  default_weight = number<br>  spot_base  = number<br>  spot_weight = number<br>}))</pre> | 

### `langflow` (optional)

Options regarding the langflow deployment. If not set, langflow is not created. Must have a custom domain at hand to use this.

| Field      | Description | Type |
| ---------- | ----------- | ---- |
| version    | The image version to use for the deployment; defaults to "latest". | `optional(string)` |
| domain     | The domain name to use for the service; used in the listener routing rules. | `string` |
| env        | Environment variables to set for the service. | `optional(map(string))` |
| containers | Options for the ECS service.<br>- cpu: The amount of CPU to allocate to the service. Defaults to 1024.<br>- memory: The amount of memory to allocate to the service. Defaults to 2048 (Mi).<br>- min_instances: The minimum number of instances to run. Defaults to 1.<br>- max_instances: The maximum number of instances to run. Defaults to 100. | <pre>optional(object({<br>  cpu           = optional(number)<br>  memory        = optional(number)<br>  min_instances = optional(number)<br>  max_instances = optional(number)<br>}))</pre> |

### `assistants` (optional)

Options regarding the astra-assistants-api deployment. If not set, assistants is not created. Must have a custom domain at hand to use this.

| Field      | Description | Type |
| ---------- | ----------- | ---- |
| version    | The image version to use for the deployment; defaults to "latest". | `optional(string)` |
| domain     | The domain name to use for the service; used in the listener routing rules. | `string` |
| env        | Environment variables to set for the service. | `optional(map(string))` |
| db         | Options for the database Astra Assistants uses.<br>- regions: The regions to deploy the database to. Defaults to the first available region.<br>- deletion_protection: Whether to enable deletion protection on the database.<br>- cloud_provider: The cloud provider to use for the database. Defaults to "gcp". | <pre>optional(object({<br>  regions             = optional(set(string))<br>  deletion_protection = optional(bool)<br>  cloud_provider      = optional(string)<br>}))</pre> |
| containers | Options for the ECS service.<br>- cpu: The amount of CPU to allocate to the service. Defaults to 1024.<br>- memory: The amount of memory to allocate to the service. Defaults to 2048 (Mi).<br>- min_instances: The minimum number of instances to run. Defaults to 1.<br>- max_instances: The maximum number of instances to run. Defaults to 100. | <pre>optional(object({<br>  cpu           = optional(number)<br>  memory        = optional(number)<br>  min_instances = optional(number)<br>  max_instances = optional(number)<br>}))</pre> |

### `vector_dbs` optional

A list of configuration for each vector-enabled DB you may want to create/deploy. No custom domain is required to use this.

| Field                | Description                                                                    | Type                    |
| -------------------- | ------------------------------------------------------------------------------ | ----------------------- |
| name                 | The name of the database to create.                                            | `string`                |
| regions              | The regions to deploy the database to. Defaults to the first available region. | `optional(set(string))` |
| keyspace             | The keyspace to use for the database. Defaults to "default_keyspace".          | `optional(string)`      |
| cloud_provider       | The cloud provider to use for the database. Defaults to "aws".                 | `optional(string)`      |
| deletion_protection  | Whether to enable deletion protection on the database.                         | `optional(bool)`        |

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
