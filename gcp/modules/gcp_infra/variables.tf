variable "project_config" {
  type = object({
    project_id      = optional(string)
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
    location    = optional(string)
    make_public = optional(bool)
  })
}

variable "components" {
  type = map(object({
    name         = string
    domain       = string
    service_name = string
  }))
}
