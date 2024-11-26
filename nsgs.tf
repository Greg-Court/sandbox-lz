# Create NSGs for each subnet except the excluded ones
resource "azurerm_network_security_group" "nsgs" {
  for_each = var.enable_nsgs ? {
    for subnet in local.subnets :
    subnet.key => subnet
    if !contains(["AzureFirewallSubnet", "AzureBastionSubnet", "GatewaySubnet"], subnet.subnet_name)
  } : {}

  name                = "${each.value.subnet_name}-nsg"
  location            = var.loc
  resource_group_name = each.value.resource_group
}

# Associate NSGs with their corresponding subnets, excluding the specified subnets
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each = var.enable_nsgs ? azurerm_network_security_group.nsgs : {}

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = each.value.id
}