provider "astra" {
  token = var.astra_token
}

provider "google" {
  region = "us-west-2"
}

provider "aws" {
  region  = "us-west-2"
  profile = var.aws_profile
}
