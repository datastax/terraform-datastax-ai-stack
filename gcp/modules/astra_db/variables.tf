variable "config" {
  type = object({
    name                = string
    regions             = optional(set(string))
    keyspace            = optional(string)
    cloud_provider      = optional(string)
    deletion_protection = optional(bool)
  })
}

variable "cloud_provider" {
  type = string
}
