terraform {
  required_providers {
    astra = {
      source  = "datastax/astra"
      version = "~> 2.3.3"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.27.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.47.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.106.0"
    }
  }
}
