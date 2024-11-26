locals {
  virtual_networks = {
    "vnet-hub-${var.loc_short}-01" = {
      address_space  = ["10.0.0.0/20"]
      resource_group = azurerm_resource_group.hub.name
      dns_servers    = [local.domain_controller_ip]
      subnets = {
        "AzureFirewallSubnet"   = { address_prefix = "10.0.0.0/24" }
        "AzureBastionSubnet"    = { address_prefix = "10.0.1.0/24" }
        "GatewaySubnet"         = { address_prefix = "10.0.2.0/24" }
        "PrivateEndpointSubnet" = { address_prefix = "10.0.15.0/24" }
      }
    }
    "vnet-adds-${var.loc_short}-01" = {
      address_space  = ["10.1.0.0/20"]
      resource_group = azurerm_resource_group.identity.name
      dns_servers    = [local.domain_controller_ip]
      subnets = {
        "ADDSSubnet"            = { address_prefix = "10.1.0.0/24" }
        "PrivateEndpointSubnet" = { address_prefix = "10.1.15.0/24" }
      }
    }
    "vnet-main-${var.loc_short}-01" = {
      address_space  = ["10.2.0.0/20"]
      resource_group = azurerm_resource_group.main.name
      dns_servers    = [local.domain_controller_ip]
      subnets = {
        "VM1Subnet"             = { address_prefix = "10.2.0.0/24" }
        "VM2Subnet"             = { address_prefix = "10.2.1.0/24" }
        "PrivateEndpointSubnet" = { address_prefix = "10.2.15.0/24" }
      }
    }
  }

  subnets = flatten([
    for vnet_key, vnet in local.virtual_networks : [
      for subnet_key, subnet in vnet.subnets : {
        key            = "${vnet_key}/${subnet_key}"
        vnet_name      = vnet_key
        subnet_name    = subnet_key
        address_prefix = subnet.address_prefix
        resource_group = vnet.resource_group
      }
    ]
  ])

}

# Create Virtual Networks
resource "azurerm_virtual_network" "vnets" {
  for_each            = local.virtual_networks
  name                = each.key
  address_space       = each.value.address_space
  location            = var.loc
  resource_group_name = each.value.resource_group
}

# Create Subnets
resource "azurerm_subnet" "subnets" {
  for_each = { for subnet in local.subnets : subnet.key => subnet }

  name                 = each.value.subnet_name
  address_prefixes     = [each.value.address_prefix]
  resource_group_name  = each.value.resource_group
  virtual_network_name = azurerm_virtual_network.vnets[each.value.vnet_name].name
}

# Create VNet Peerings from Hub to Spokes
resource "azurerm_virtual_network_peering" "hub_to_spokes" {
  for_each = {
    for vnet_name, vnet in local.virtual_networks :
    vnet_name => vnet if vnet_name != "vnet-hub-${var.loc_short}-01"
  }

  name                         = "${azurerm_virtual_network.vnets["vnet-hub-${var.loc_short}-01"].name}-to-${each.key}"
  resource_group_name          = azurerm_virtual_network.vnets["vnet-hub-${var.loc_short}-01"].resource_group_name
  virtual_network_name         = azurerm_virtual_network.vnets["vnet-hub-${var.loc_short}-01"].name
  remote_virtual_network_id    = azurerm_virtual_network.vnets[each.key].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Create VNet Peerings from Spokes to Hub
resource "azurerm_virtual_network_peering" "spokes_to_hub" {
  for_each = azurerm_virtual_network_peering.hub_to_spokes

  name                         = "${azurerm_virtual_network.vnets[each.key].name}-to-${azurerm_virtual_network.vnets["vnet-hub-${var.loc_short}-01"].name}"
  resource_group_name          = azurerm_virtual_network.vnets[each.key].resource_group_name
  virtual_network_name         = azurerm_virtual_network.vnets[each.key].name
  remote_virtual_network_id    = azurerm_virtual_network.vnets["vnet-hub-${var.loc_short}-01"].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_ip_group" "shared" {
  name                = "ipg-shared-${var.loc_short}-01"
  location            = var.loc
  resource_group_name = azurerm_resource_group.hub.name

  cidrs = flatten([
    for vnet_key, vnet in local.virtual_networks : vnet.address_space
  ])
}