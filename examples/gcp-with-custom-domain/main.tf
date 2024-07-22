provider "astra" {
  token = var.astra_token
}

provider "google" {
  region = "us-central1"
}

module "datastax-ai-stack-gcp" {
  source = "../../modules/gcp"

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
