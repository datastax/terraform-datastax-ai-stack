variable "astra_token" {
  type     = string
  nullable = false
}

variable "google_region" {
  type    = string
  default = "us-central1"
}

variable "billing_account" {
  type     = string
  nullable = false
}

variable "dns_name" {
  type     = string
  nullable = false
}
