variable "chat_ui" {
  type = object({
    public_origin = string
    task_model    = any
    models        = any
    mongodb_url   = string
    api_keys = object({
      hf_token             = optional(string)
      openai_api_key       = optional(string)
      perplexityai_api_key = optional(string)
      cohere_api_key       = optional(string)
      gemini_api_key       = optional(string)
    })
    vm_config = optional(object({
      instance_type  = string
      image_id       = string
      subnet_id      = optional(string)
      region_or_zone = optional(string)
    }))
  })
  nullable = true
}

variable "cloud_provider" {
  type = object({
    name = string
    ssh = optional(object({
      aws_public_key_name = optional(string)
      gcp_user            = optional(string)
      gcp_pub_key         = optional(string)
    }))
  })

  validation {
    condition     = var.cloud_provider.name == "aws" || var.cloud_provider.name == "gcp"
    error_message = "provider.name must be either 'aws' or 'gcp'"
  }
}

variable "astra_token" {
  type = string
}
