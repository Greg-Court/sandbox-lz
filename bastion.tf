# Public IP for Azure Bastion
resource "azurerm_public_ip" "bastion_pip" {
  count               = var.deploy_bastion ? 1 : 0
  name                = "pip-bastion-hub-${var.loc_short}-01"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.loc
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Azure Bastion Host
resource "azurerm_bastion_host" "bastion" {
  count               = var.deploy_bastion ? 1 : 0
  name                = "bastion-hub-${var.loc_short}-01"
  location            = var.loc
  resource_group_name = azurerm_resource_group.hub.name

  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = azurerm_subnet.hub_subnets["vnet-hub-${var.loc_short}-01/AzureBastionSubnet"].id
    public_ip_address_id = azurerm_public_ip.bastion_pip[0].id
  }

  sku = "Standard"
}
