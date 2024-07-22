# module "datastax-ai-stack-aws" {
#   source = "../modules/aws"

#   domain_config = {
#     auto_route53_setup = true
#     hosted_zones = {
#       default = { zone_name = "enterprise-ai-stack.com" }
#     }
#   }

#   langflow = {
#     domain = "langflow.enterprise-ai-stack.com"
#     postgres_db = {
#       instance_class      = "db.t3.micro"
#       deletion_protection = false
#     }
#   }

#   # assistants = {
#   #   domain = "assistants.enterprise-ai-stack.com"
#   #   astra_db = {
#   #     deletion_protection = false
#   #   }
#   # }

#   # vector_dbs = [{
#   #   name      = "my_db"
#   #   keyspaces = ["main_keyspace", "other_keyspace"]
#   #   deletion_protection = false
#   # }]
# }

# module "datastax-ai-stack-gcp" {
#   source = "../modules/gcp"

#   project_config = {
#     create_project = {
#       billing_account = var.billing_account
#     }
#   }

#   domain_config = {
#     auto_cloud_dns_setup = true
#     astra_zones = {
#       default = { dns_name = "gcp.enterprise-ai-stack.com." }
#     }
#   }

#   langflow = {
#     domain = "langflow.gcp.enterprise-ai-stack.com"
#     postgres_db = {
#       tier                = "db-f1-micro"
#       deletion_protection = false
#     }
#   }

#   # assistants = {
#   #   # domain = "assistants.gcp.enterprise-ai-stack.com"
#   #   astra_db = {
#   #     regions             = ["us-east1"]
#   #     deletion_protection = false
#   #   }
#   # }

#   # vector_dbs = [{
#   #   name      = "my_db"
#   #   keyspaces = ["main_keyspace", "other_keyspace"]
#   #   deletion_protection = false
#   # }]
# }

module "datastax-ai-stack-azure" {
  source = "../modules/azure"

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
    postgres_db = {
      sku_name = "B_Standard_B1ms"
    }
  }

  # assistants = {
  #   subdomain = "assistants"
  #   astra_db = {
  #     deletion_protection = false
  #   }
  # }

  # vector_dbs = [{
  #   name                = "my_db"
  #   keyspaces           = ["main_keyspace", "other_keyspace"]
  #   deletion_protection = false
  # }]
}
