# Create NSGs for all subnets except the excluded ones
resource "azurerm_network_security_group" "nsgs" {
  for_each = var.enable_nsgs ? {
    for subnet in local.subnets :
    subnet.key => subnet
    if !contains(["AzureFirewallSubnet", "AzureBastionSubnet", "GatewaySubnet"], subnet.subnet_name)
  } : {}

  name                = "nsg-${each.value.vnet_name}_${each.value.subnet_name}"
  location            = var.loc
  resource_group_name = each.value.resource_group
}

# Associate NSGs with their corresponding subnets, excluding the specified subnets
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each = var.enable_nsgs ? azurerm_network_security_group.nsgs : {}

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = each.value.id
}

resource "azurerm_network_security_rule" "allow_outbound_100" {
  for_each = azurerm_network_security_group.nsgs

  name                        = "allow-outbound-100"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "100.0.0.0/16"
  network_security_group_name = each.value.name
  resource_group_name         = each.value.resource_group_name
}

resource "azurerm_network_security_rule" "allow_inbound_100" {
  for_each = azurerm_network_security_group.nsgs

  name                        = "allow-inbound-100"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "100.0.0.0/16"
  destination_address_prefix  = "*"
  network_security_group_name = each.value.name
  resource_group_name         = each.value.resource_group_name
}
