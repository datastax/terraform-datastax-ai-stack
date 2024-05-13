variable "astra_token" {
  type = string
}

variable "aws_profile" {
  type     = string
  nullable = true
  default  = null
}

variable "billing_account" {
  type     = string
  nullable = true
  default  = null
}
