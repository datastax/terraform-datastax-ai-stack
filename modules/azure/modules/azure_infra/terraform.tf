terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.79.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.11.0"
    }
  }
}
