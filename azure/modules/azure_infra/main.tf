resource "azurerm_resource_group" "this" {
  count = var.resource_group_config.create_resource_group != null ? 1 : 0

  name     = var.resource_group_config.create_resource_group.name
  location = var.resource_group_config.create_resource_group.location
}

data "azurerm_resource_group" "this" {
  count = var.resource_group_config.create_resource_group == null ? 1 : 0

  name = var.resource_group_config.resource_group_name
}

locals {
  resource_group_name = coalesce(var.resource_group_config.resource_group_name, azurerm_resource_group.this.name)
  location = coalesce(var.resource_group_config.create_resource_group.location, azurerm_resource_group.this.location)
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-enterprise-gpts"
  location            = local.location
  resource_group_name = local.resource_group_name
}

resource "azurerm_container_app_environment" "this" {
  name                       = "cae-enterprise-gpts"
  location                   = local.location
  resource_group_name        = local.resource_group_name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
}

locals {
  dns_zones = coalesce(var.domain_config.dns_zones, {})

  partial_dns_zones_lut = {
    for name, _ in var.components : name => try(local.dns_zones[name], local.dns_zones["default"])
  }

  dns_zones_lut = {
    for name, _ in var.components : name => {
      dns_zone            = local.partial_dns_zones_lut[name]["dns_zone"]
      resource_group_name = data.azurerm_dns_zone.zones[name].resource_group_name
    }
  }
}

data "azurerm_dns_zone" "zones" {
  for_each = var.components

  name                = local.partial_dns_zones_lut[each.key]["dns_zone"]
  resource_group_name = local.partial_dns_zones_lut[each.key]["resource_group_name"]
}

resource "azurerm_dns_txt_record" "verification_records" {
  for_each = var.components

  name                = length(each.value.subdomain) > 0 ? "asuid.${each.value.subdomain}" : "asuid"
  resource_group_name = local.dns_zones_lut[each.key]["resource_group_name"]
  zone_name           = local.dns_zones_lut[each.key]["dns_zone"]
  ttl                 = 300

  record {
    value = each.value.domain_verification_id
  }
}

resource "azurerm_dns_cname_record" "cname_record" {
  for_each = var.components

  name                = each.value.subdomain
  zone_name           = local.dns_zones_lut[each.key]["dns_zone"]
  resource_group_name = local.dns_zones_lut[each.key]["resource_group_name"]
  ttl                 = 60
  record              = each.value.app_fqdn

  depends_on = [azurerm_dns_txt_record.verification_records]
}

resource "time_sleep" "dns_propagation" {
  for_each = var.components

  create_duration = "60s"

  depends_on = [azurerm_dns_txt_record.verification_records, azurerm_dns_cname_record.cname_record]

  triggers = {
    url            = "${azurerm_dns_cname_record.cname_record[each.key].name}.${local.dns_zones_lut[each.key]["dns_zone"]}",
    verificationId = each.value.domain_verification_id,
    record         = azurerm_dns_cname_record.cname_record[each.key].record,
  }
}

resource "azapi_update_resource" "custom_domain" {
  for_each = var.components

  type        = "Microsoft.App/containerApps@2023-05-01"
  resource_id = each.value.app_id

  body = jsonencode({
    properties = {
      configuration = {
        ingress = {
          customDomains = [
            {
              bindingType = "Disabled",
              name        = time_sleep.dns_propagation[each.key].triggers.url,
            }
          ]
        }
      }
    }
  })
}

resource "azapi_resource" "managed_certificate" {
  for_each = var.components

  depends_on = [time_sleep.dns_propagation]
  type      = "Microsoft.App/ManagedEnvironments/managedCertificates@2023-05-01"
  name      = "${each.key}-cert"
  parent_id = azurerm_container_app_environment.this.id
  location  = local.location

  body = jsonencode({
    properties = {
      subjectName             = time_sleep.dns_propagation[each.key].triggers.url
      domainControlValidation = "CNAME"
    }
  })

  response_export_values = ["*"]
}

resource "azapi_update_resource" "custom_domain_binding" {
  for_each = var.components

  type        = "Microsoft.App/containerApps@2023-05-01"
  resource_id = each.value.app_id

  body = jsonencode({
    properties = {
      configuration = {
        ingress = {
          customDomains = [
            {
              bindingType   = "SniEnabled",
              name          = time_sleep.dns_propagation[each.key].triggers.url,
              certificateId = jsondecode(azapi_resource.managed_certificate[each.key].output).id
            }
          ]
        }
      }
    }
  })
}

output "container_app_environment_id" {
  value = azurerm_container_app_environment.this.id
}

output "resource_group_name" {
  value = local.resource_group_name
}

output "resource_group_id" {
  value = azurerm_resource_group.this.id
}
