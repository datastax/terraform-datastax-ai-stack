locals {
  chat_ui_user_data_script = templatefile("${path.module}/chat_ui_user_data.sh", {
    token                = var.astra_token
    mongodb_url          = var.chat_ui.mongodb_url
    hf_token             = var.chat_ui.api_keys.hf_token
    openai_api_key       = var.chat_ui.api_keys.openai_api_key
    perplexityai_api_key = var.chat_ui.api_keys.perplexityai_api_key
    cohere_api_key       = var.chat_ui.api_keys.cohere_api_key
    gemini_api_key       = var.chat_ui.api_keys.gemini_api_key
    public_origin        = var.chat_ui.public_origin
    task_model           = var.chat_ui.task_model
    models               = var.chat_ui.models
  })
}

resource "aws_instance" "chat_ui_vm" {
  count = var.cloud_provider.name == "aws" && var.chat_ui.vm_config != null ? 1 : 0

  instance_type     = var.chat_ui.vm_config.instance_type
  ami               = var.chat_ui.vm_config.image_id
  subnet_id         = var.chat_ui.vm_config.subnet_id
  key_name          = var.cloud_provider.ssh.aws_public_key_name
  availability_zone = var.chat_ui.vm_config.region_or_zone

  tags = {
    Name = "chat-ui-instance"
  }

  user_data = local.chat_ui_user_data_script
}

resource "google_compute_instance" "chat_ui_vm" {
  count = var.cloud_provider.name == "gcp" && var.chat_ui.vm_config != null ? 1 : 0

  name         = "chat-ui-instance"
  machine_type = var.chat_ui.vm_config.instance_type
  zone         = var.chat_ui.vm_config.region_or_zone

  boot_disk {
    initialize_params {
      image = var.chat_ui.vm_config.image_id
    }
  }

  network_interface {
    network    = "default"
    subnetwork = var.chat_ui.vm_config.subnet_id
  }

  metadata = {
    ssh-keys = "${var.cloud_provider.ssh.gcp_user}:${var.cloud_provider.ssh.gcp_pub_key}"
  }

  lifecycle {
    prevent_destroy = false
  }

  metadata_startup_script = local.chat_ui_user_data_script
}
