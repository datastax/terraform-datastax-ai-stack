terraform {
  required_providers {
    astra = {
      source  = "datastax/astra"
      version = "~> 2.3.3"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.106.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.13.0"
    }
  }
}
