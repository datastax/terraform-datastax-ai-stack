terraform {
  required_version = ">= 1.0"

  required_providers {
    astra = {
      source  = "datastax/astra"
      version = ">= 2.3.3"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 5.12.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.79.0"
    }
  }
}
