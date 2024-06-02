resource "azurerm_resource_group" "my_first_app" {
  name     = "rg-enterprise-gpts"
  location = "westeurope"
}

resource "azurerm_log_analytics_workspace" "my_first_app" {
  name                = "log-enterprise-gpts"
  location            = azurerm_resource_group.my_first_app.location
  resource_group_name = azurerm_resource_group.my_first_app.name
}

resource "azurerm_container_app_environment" "my_first_app" {
  name                      = "cae-enterprise-gpts"
  location                   = azurerm_resource_group.my_first_app.location
  resource_group_name        = azurerm_resource_group.my_first_app.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.my_first_app.id
}

output "container_app_environment_id" {
  value = azurerm_container_app_environment.my_first_app.id
}

output "resource_group_name" {
  value = azurerm_resource_group.my_first_app.name
}
