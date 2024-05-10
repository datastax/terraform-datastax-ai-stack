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
