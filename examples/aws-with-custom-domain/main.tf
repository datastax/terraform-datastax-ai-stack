provider "astra" {
  token = var.astra_token
}

provider "aws" {
  region  = "us-east-1"
  profile = var.aws_profile
}

module "datastax-ai-stack-aws" {
  source = "../../modules/aws"

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
