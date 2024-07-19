terraform {
  required_version = ">= 1.0"

  required_providers {
    astra = {
      source  = "datastax/astra"
      version = ">= 2.3.3"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}
