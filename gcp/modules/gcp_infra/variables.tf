variable "gcp_config" {
  type = object({
    project_id      = optional(string)
    project_options = optional(object({
      name            = optional(string)
      org_id          = optional(string)
      billing_account = string
    }))
    cloud_run_location = optional(string)
  })
}
