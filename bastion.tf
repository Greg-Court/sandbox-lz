# Public IP for Azure Bastion
resource "azurerm_public_ip" "bastion_pip" {
  name                = "pip-bastion-hub-${var.loc_short}-01"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.loc
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Azure Bastion Host
resource "azurerm_bastion_host" "bastion" {
  count               = var.create_bastion ? 1 : 0
  name                = "bastion-hub-${var.loc_short}-01"
  location            = var.loc
  resource_group_name = azurerm_resource_group.hub.name

  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = azurerm_subnet.subnets["vnet-hub-${var.loc_short}-01/AzureBastionSubnet"].id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }

  sku = "Standard"
}
