resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.loc_short}-01"
  location            = var.loc
  resource_group_name = azurerm_resource_group.mgmt.name
  sku                 = "PerGB2018"

  retention_in_days = 30
}
