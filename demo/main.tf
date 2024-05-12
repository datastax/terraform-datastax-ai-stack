module "enterprise-gpts-aws" {
  source = "../aws"

  domain_config = {
    auto_route53_setup = true
    auto_acm_cert      = true
    hosted_zones = {
      default = { name = "enterprise-ai-stack.com." }
    }
  }

  langflow = {
    domain = "langflow.enterprise-ai-stack.com"
  }
}

# module "enterprise-gpts-gcp" {
#   source = "../gcp"
#
#   project_config = {
#     project_options = {
#       billing_account = "01F914-6F67E3-785C6A"
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
#       regions = ["us-east1"]
#       deletion_protection = false
#     }
#   }
# }
