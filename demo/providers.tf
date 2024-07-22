provider "astra" {
  token = var.astra_token
}

provider "google" {
  region = "us-central1"
}

provider "aws" {
  region  = "us-west-2"
  profile = var.aws_profile
}

provider "azurerm" {
  features {}
}
