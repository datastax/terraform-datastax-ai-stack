# DataStax AI Stack Terraform Module

Terraform module which helps you quickly deploy an opinionated AI/RAG stack to your cloud provider of choice, provided by DataStax.

It offers multiple easy-to-deploy components, including:
 - Langflow
 - Astra Assistants API
 - Astra Vector Databases

This is not a module itself, but rather an aggregation of each supported cloud provider: AWS, GCP, and Azure. 
View each submodule's README for more information about how to use it.

Module registry links:
- https://registry.terraform.io/modules/datastax/ai-stack/aws/latest
- https://registry.terraform.io/modules/datastax/ai-stack/gcp/latest
- https://registry.terraform.io/modules/datastax/ai-stack/azure/latest

## Usage examples

### AWS

```hcl
module "datastax-ai-stack-aws" {
  source  = "datastax/ai-stack/aws"
  version = "~> 1.0"

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

### GCP

```hcl
module "datastax-ai-stack-gcp" {
  source  = "datastax/ai-stack/gcp"
  version = "~> 1.0"

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

### Azure

```hcl
module "datastax-ai-stack-azure" {
  source  = "datastax/ai-stack/azure"
  version = "~> 1.0"

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
