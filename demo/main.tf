# module "enterprise-gpts-aws" {
#   source = "../aws"
#
#   domain_config = {
#     auto_route53_setup = true
#     auto_acm_cert      = true
#     hosted_zones = {
#       default = { name = "enterprise-ai-stack.com." }
#     }
#   }
#
#   langflow = {
#     domain = "langflow.enterprise-ai-stack.com"
#   }
#
#   assistants = {
#     domain = "assistants.enterprise-ai-stack.com"
#     db = {
#       regions = ["us-east-2"]
#       deletion_protection = false
#     }
#   }
# }

module "enterprise-gpts-gcp" {
  source = "../gcp"

  project_config = {
    project_options = {
      billing_account = var.billing_account
    }
  }

  domain_config = {
    auto_cloud_dns_setup = true
    managed_zones = {
      default = { dns_name = "gcp.enterprise-ai-stack.com." }
    }
  }

  langflow = {
    domain = "langflow.gcp.enterprise-ai-stack.com."
  }

  assistants = {
    domain = "assistants.gcp.enterprise-ai-stack.com."
    db = {
      regions             = ["us-east1"]
      deletion_protection = false
    }
  }
}
