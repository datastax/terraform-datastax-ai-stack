provider "astra" {
  token = var.astra_token
}

provider "azurerm" {
  features {}
}

module "datastax-ai-stack-azure" {
  source = "../../modules/azure"

  resource_group_config = {
    create_resource_group = {
      name     = "datastax-ai-stack"
      location = "East US"
    }
  }

  domain_config = {
    auto_azure_dns_setup = false
  }

  langflow = {
    postgres_db = {
      sku_name = "B_Standard_B1ms"
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
