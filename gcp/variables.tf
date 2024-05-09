variable "gcp_config" {
  type = object({
    project_id      = optional(string)
    project_options = optional(object({
      name            = optional(string)
      org_id          = optional(string)
      billing_account = string
    }))
    cloud_run = object({
      location    = optional(string)
      make_public = optional(bool)
    })
  })

  validation {
    condition     = var.gcp_config.project_id != null && var.gcp_config.project_options == null || var.gcp_config.project_id == null && var.gcp_config.project_options != null
    error_message = "Either project_id or project_options must be set"
  }

  nullable = false
}

variable "assistants" {
  type = object({
    domain = optional(string)
    db     = optional(object({
      regions             = set(string)
      deletion_protection = optional(bool)
      cloud_provider      = optional(string)
    }))
    container_limits = optional(object({
      cpu    = optional(number)
      memory = optional(number)
    }))
  })
  default = null
}

variable "langflow" {
  type = object({
    domain           = optional(string)
    container_limits = optional(object({
      cpu    = optional(number)
      memory = optional(number)
    }))
  })
  default = null
}

variable "vector_dbs" {
  type = list(object({
    name                = string
    regions             = set(string)
    keyspace            = optional(string)
    cloud_provider      = optional(string)
    deletion_protection = optional(bool)
  }))
  nullable = false
  default  = []
}
