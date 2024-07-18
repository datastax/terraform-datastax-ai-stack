# module "datastax-ai-stack-aws" {
#   source = "../aws"

#   domain_config = {
#     auto_route53_setup = true
#     hosted_zones = {
#       default = { zone_name = "enterprise-ai-stack.com" }
#     }
#   }

#   langflow = {
#     domain = "langflow.enterprise-ai-stack.com"
#   }

#   assistants = {
#     domain = "assistants.enterprise-ai-stack.com"
#     db = {
#       deletion_protection = false
#     }
#   }

#   vector_dbs = [{
#     name      = "my_db"
#     keyspaces = ["main_keyspace", "other_keyspace"]
#     deletion_protection = false
#   }]
# }

# module "datastax-ai-stack-gcp" {
#   source = "../gcp"

#   project_config = {
#     create_project = {
#       billing_account = var.billing_account
#     }
#   }

#   domain_config = {
#     auto_cloud_dns_setup = true
#     managed_zones = {
#       default = { dns_name = "gcp.enterprise-ai-stack.com." }
#     }
#   }

#   langflow = {
#     domain = "langflow.gcp.enterprise-ai-stack.com"
#   }

#   assistants = {
#     # domain = "assistants.gcp.enterprise-ai-stack.com"
#     db = {
#       regions             = ["us-east1"]
#       deletion_protection = false
#     }
#   }

#   vector_dbs = [{
#     name      = "my_db"
#     keyspaces = ["main_keyspace", "other_keyspace"]
#     deletion_protection = false
#   }]
# }

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
  }

  assistants = {
    subdomain = "assistants"
    db = {
      deletion_protection = false
    }
  }

  vector_dbs = [{
    name      = "my_db"
    keyspaces = ["main_keyspace", "other_keyspace"]
    deletion_protection = false
  }]
}
