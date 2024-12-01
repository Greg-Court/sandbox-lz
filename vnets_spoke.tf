# Local variable for the Domain Controller IP
locals {
  spoke_vnets = {
    "vnet-adds-${var.loc_short}-01" = {
      hub            = azurerm_virtual_network.hub_vnets["vnet-hub-${var.loc_short}-01"]
      vnet_name      = "vnet-adds-${var.loc_short}-01"
      location       = var.loc
      address_space  = ["10.0.16.0/20"]
      resource_group = azurerm_resource_group.identity.name
      dns_servers    = [local.domain_controller_ip]
      vnet_routes = {
        "Internet-to-Firewall" = {
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = azurerm_firewall.primary.ip_configuration[0].private_ip_address
        }
        "VNetLocal-to-Firewall" = {
          address_prefix         = "10.0.16.0/20"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = azurerm_firewall.primary.ip_configuration[0].private_ip_address
        }
        "AppGatewaySubnet-to-Firewall" = {
          address_prefix         = azurerm_subnet.hub_subnets["vnet-hub-${var.loc_short}-01/AppGatewaySubnet"].address_prefixes[0]
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = azurerm_firewall.primary.ip_configuration[0].private_ip_address
        }
      }
      subnets = {
        "ADDSSubnet" = {
          address_prefix = "10.0.16.0/24"
          routes         = null
        }
        "PrivateEndpointSubnet" = {
          address_prefix = "10.0.31.0/24"
          routes         = null
        }
      }
    }
    "vnet-main-${var.loc_short}-01" = {
      hub            = azurerm_virtual_network.hub_vnets["vnet-hub-${var.loc_short}-01"]
      vnet_name      = "vnet-main-${var.loc_short}-01"
      location       = var.loc
      address_space  = ["10.0.32.0/20"]
      resource_group = azurerm_resource_group.main.name
      dns_servers    = [local.domain_controller_ip]
      vnet_routes = {
        "Internet-to-Firewall" = {
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = azurerm_firewall.primary.ip_configuration[0].private_ip_address
        }
        "VNetLocal-to-Firewall" = {
          address_prefix         = "10.0.32.0/20"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = azurerm_firewall.primary.ip_configuration[0].private_ip_address
        }
        "AppGatewaySubnet-to-Firewall" = {
          address_prefix         = azurerm_subnet.hub_subnets["vnet-hub-${var.loc_short}-01/AppGatewaySubnet"].address_prefixes[0]
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = azurerm_firewall.primary.ip_configuration[0].private_ip_address
        }
      }
      subnets = {
        "WindowsSubnet" = {
          address_prefix = "10.0.32.0/24"
          routes         = null
        }
        "LinuxSubnet" = {
          address_prefix = "10.0.33.0/24"
          routes         = null
        }
        "PrivateEndpointSubnet" = {
          address_prefix = "10.0.47.0/24"
          routes         = null
        }
      }
    }
  }

  # Flatten subnets and prepare route table names
  spoke_subnets = flatten([
    for vnet_key, vnet in local.spoke_vnets : [
      for subnet_name, subnet in vnet.subnets : {
        key                   = "${vnet_key}/${subnet_name}"
        vnet_name             = vnet.vnet_name
        subnet_name           = subnet_name
        address_prefix        = subnet.address_prefix
        resource_group        = vnet.resource_group
        location              = vnet.location
        subnet_routes         = subnet.routes
        route_table_name      = subnet.routes != null ? "rt-${lower(replace(subnet_name, "Subnet", "sn"))}-${replace(vnet.vnet_name, "vnet-", "")}" : null
        vnet_route_table_name = vnet.vnet_routes != null ? "rt-${replace(vnet.vnet_name, "vnet-", "")}" : null
      }
    ]
  ])

  # Define Route Tables per VNet
  spoke_vnet_route_tables = {
    for vnet_key, vnet in local.spoke_vnets :
    "rt-${replace(vnet.vnet_name, "vnet-", "")}" => {
      location            = vnet.location
      resource_group_name = vnet.resource_group
      routes              = vnet.vnet_routes
      vnet_name           = vnet.vnet_name
    }
    if vnet.vnet_routes != null
  }

  # Define Route Tables per Subnet
  spoke_subnet_route_tables = {
    for subnet in local.spoke_subnets :
    subnet.route_table_name => {
      location            = subnet.location
      resource_group_name = subnet.resource_group
      routes              = subnet.subnet_routes
      vnet_name           = subnet.vnet_name
    }
    if subnet.route_table_name != null
  }

  # Merge all route tables
  spoke_all_route_tables = merge(local.spoke_vnet_route_tables, local.spoke_subnet_route_tables)
}

output "spoke_subnets_debug" {
  value = local.spoke_subnets
}

output "spoke_all_route_tables_debug" {
  value = local.spoke_all_route_tables
}

# Create Spoke Virtual Networks
resource "azurerm_virtual_network" "spoke_vnets" {
  for_each = local.spoke_vnets

  name                = each.value.vnet_name
  location            = each.value.location
  resource_group_name = each.value.resource_group
  address_space       = each.value.address_space
  dns_servers         = each.value.dns_servers
}

# Create Spoke Subnets
resource "azurerm_subnet" "spoke_subnets" {
  for_each = { for subnet in local.spoke_subnets : subnet.key => subnet }

  name                 = each.value.subnet_name
  address_prefixes     = [each.value.address_prefix]
  resource_group_name  = each.value.resource_group
  virtual_network_name = azurerm_virtual_network.spoke_vnets[each.value.vnet_name].name
}

# Create Spoke Route Tables
resource "azurerm_route_table" "spoke_rt" {
  for_each = local.spoke_all_route_tables

  name                = each.key
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  # Dynamically enable/disable BGP route propagation
  bgp_route_propagation_enabled = try(
    flatten([
      for subnet in local.spoke_subnets :
      subnet if subnet.vnet_name == each.value.vnet_name && subnet.route_table_name == each.key
    ])[0].bgp_enabled,
    false
  )

  dynamic "route" {
    for_each = each.value.routes != null ? [for route_name, route in each.value.routes : merge(route, { name = route_name })] : []

    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = lookup(route.value, "next_hop_in_ip_address", null)
    }
  }
}


locals {
  spoke_subnet_route_table_associations = {
    for subnet in local.spoke_subnets :
    subnet.key => {
      subnet_id = azurerm_subnet.spoke_subnets[subnet.key].id
      route_table_id = (
        subnet.route_table_name != null ? azurerm_route_table.spoke_rt[subnet.route_table_name].id :
        subnet.vnet_route_table_name != null ? azurerm_route_table.spoke_rt[subnet.vnet_route_table_name].id :
        null
      )
    }
    if(
      (subnet.route_table_name != null || subnet.vnet_route_table_name != null) &&
      !contains(["AzureBastionSubnet"], subnet.subnet_name)
    )
  }
}

resource "azurerm_subnet_route_table_association" "spoke_assoc" {
  for_each = local.spoke_subnet_route_table_associations

  subnet_id      = each.value.subnet_id
  route_table_id = each.value.route_table_id
}
# Peering from Spoke to Hub
resource "azurerm_virtual_network_peering" "hub_spoke" {
  for_each = local.spoke_vnets

  name                      = "peering-${each.value.vnet_name}-to-hub"
  resource_group_name       = each.value.resource_group
  virtual_network_name      = each.value.vnet_name
  remote_virtual_network_id = each.value.hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Peering from Hub to Spoke
resource "azurerm_virtual_network_peering" "spoke_hub" {
  for_each = local.spoke_vnets

  name                      = "peering-hub-to-${each.value.vnet_name}"
  resource_group_name       = each.value.hub.resource_group_name
  virtual_network_name      = each.value.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_vnets[each.key].id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Spoke NSGs and Associations
resource "azurerm_network_security_group" "spoke_nsgs" {
  for_each = {
    for subnet in local.spoke_subnets :
    subnet.key => subnet
    if var.enable_nsgs && !contains(["AzureFirewallSubnet", "AzureBastionSubnet", "GatewaySubnet", "AppGatewaySubnet"], subnet.subnet_name)
  }

  name                = "nsg-${lower(replace(each.value.subnet_name, "Subnet", "sn"))}-${replace(each.value.vnet_name, "vnet-", "")}"
  location            = each.value.location
  resource_group_name = each.value.resource_group
}

resource "azurerm_subnet_network_security_group_association" "spoke_nsg_assoc" {
  for_each = azurerm_network_security_group.spoke_nsgs

  subnet_id                 = azurerm_subnet.spoke_subnets[each.key].id
  network_security_group_id = each.value.id
}
