provider "astra" {
  token = var.astra_token
}

provider "aws" {
  profile = var.aws_profile
}

module "datastax-ai-stack-aws" {
  source = "../../modules/aws"

  domain_config = {
    auto_route53_setup = false
  }

  langflow = {
    postgres_db = {
      instance_class      = "db.t3.micro"
      deletion_protection = false
    }
  }

  assistants = {
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
