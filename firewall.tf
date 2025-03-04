# Public IP for Azure Firewall
resource "azurerm_public_ip" "firewall_pip" {
  name                = "pip-azfw-hub-${var.loc_short}-01"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.loc
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "firewall_mgmt_pip" {
  count               = var.azure_firewall_sku == "Basic" ? 1 : 0
  name                = "pip-azfw-mgmt-${var.loc_short}-01"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.loc
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Azure Firewall
resource "azurerm_firewall" "primary" {
  name                = "azfw-hub-${var.loc_short}-01"
  location            = var.loc
  resource_group_name = azurerm_resource_group.hub.name

  sku_name = "AZFW_VNet"
  sku_tier = "Basic"

  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = azurerm_subnet.hub_subnets["vnet-hub-${var.loc_short}-01/AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.firewall_pip.id
  }

  dynamic "management_ip_configuration" {
    for_each = var.azure_firewall_sku == "Basic" ? [1] : []
    content {
      name                 = "mgmt-ipconfig"
      subnet_id            = azurerm_subnet.hub_subnets["vnet-hub-${var.loc_short}-01/AzureFirewallManagementSubnet"].id
      public_ip_address_id = azurerm_public_ip.firewall_mgmt_pip[0].id
    }
  }

  firewall_policy_id = azurerm_firewall_policy.primary.id
}

resource "azurerm_monitor_diagnostic_setting" "firewall_diagnostic" {
  name               = "diag-azfw-${var.loc_short}-01"
  target_resource_id = azurerm_firewall.primary.id

  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}
