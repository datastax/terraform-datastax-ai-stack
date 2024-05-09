terraform {
  required_providers {
    astra = {
      source  = "datastax/astra"
      version = "~> 2.2.8"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.47.0"
    }
  }
}
