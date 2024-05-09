terraform {
  required_providers {
    astra = {
      source  = "datastax/astra"
      version = "~> 2.2.8"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.27.0"
    }
  }
}
