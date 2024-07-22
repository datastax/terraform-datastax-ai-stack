terraform {
  required_version = ">= 1.0"

  required_providers {
    astra = {
      source  = "datastax/astra"
      version = ">= 2.3.3"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.79.0"
    }
  }
}
