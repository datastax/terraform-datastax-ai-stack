terraform {
  required_providers {
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
