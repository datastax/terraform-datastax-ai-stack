# Datastax AI stack (AWS)

Terraform module which helps you quickly deploy an opinionated AI/RAG stack to your cloud provider of choice, provided by Datastax.

It offers multiple easy-to-deploy components, including:
 - Langflow
 - Astra Assistants API
 - Vector databases

There are submodules for each supported cloud provider: AWS, GCP, and Azure. View each submodule's README for more information about
how to use it.

## Usage examples

### AWS

```hcl
module "datastax-ai-stack-aws" {
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
      name      = "my_vector_db"
      keyspaces = ["my_keyspace1", "my_keyspace2"]
    }
  ]
}
```

### GCP

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

### Azure

```hcl
module "datastax-ai-stack-azure" {
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

  vector_dbs = [
    {
      name      = "my_vector_db"
      keyspaces = ["my_keyspace1", "my_keyspace2"]
    }
  ]
}
```
