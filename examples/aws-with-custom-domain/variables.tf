variable "astra_token" {
  type = string
  nullable = false
}

variable "aws_profile" {
  type = string
  default = null
}

variable "dns_zone_name" {
  type = string
  nullable = false
}
