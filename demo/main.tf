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
#     containers = {
#       min_instances = 1
#     }
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

  langflow = {
    domain = "langflow.enterprise-ai-stack.com"
  }

  assistants = {
    domain = "assistants.enterprise-ai-stack.com"
    containers = {
      min_instances = 1
    }
    db = {
      regions = ["us-east1"]
      deletion_protection = false
    }
  }
}
