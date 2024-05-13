variable "project_config" {
  type = object({
    project_id = optional(string)
    project_options = optional(object({
      name            = optional(string)
      org_id          = optional(string)
      billing_account = string
    }))
  })

  validation {
    condition     = var.project_config.project_id != null && var.project_config.project_options == null || var.project_config.project_id == null && var.project_config.project_options != null
    error_message = "Either project_id or project_options must be set"
  }
}

variable "cloud_run_config" {
  type = object({
    location = optional(string)
  })
  nullable = true
  default  = null
}

variable "assistants" {
  type = object({
    domain = optional(string)
    db = optional(object({
      regions             = set(string)
      deletion_protection = optional(bool)
      cloud_provider      = optional(string)
    }))
    containers = optional(object({
      cpu           = optional(number)
      memory        = optional(number)
      min_instances = optional(number)
    }))
  })
  default = null
}

variable "langflow" {
  type = object({
    domain = optional(string)
    db_url = optional(string)
    containers = optional(object({
      cpu           = optional(number)
      memory        = optional(number)
      min_instances = optional(number)
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
