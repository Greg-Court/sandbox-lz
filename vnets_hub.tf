# Local variable for the Domain Controller IP
locals {
  hub_vnets = {
    "vnet-hub-${var.loc_short}-01" = {
      vnet_name      = "vnet-hub-${var.loc_short}-01"
      location       = var.loc
      address_space  = ["10.0.0.0/20"]
      resource_group = azurerm_resource_group.hub.name
      dns_servers    = [local.domain_controller_ip]
      vnet_routes    = null
      subnets = {
        "AzureFirewallSubnet" = {
          address_prefix = "10.0.0.0/24"
          routes = {
            "Internet-Out" = {
              address_prefix = "0.0.0.0/0"
              next_hop_type  = "Internet"
            }
          }
        }
        "AzureBastionSubnet" = {
          address_prefix = "10.0.1.0/24"
          routes         = null
        }
        "GatewaySubnet" = {
          address_prefix = "10.0.2.0/24"
          routes = {
            "MainVNet-to-Firewall" = {
              address_prefix         = "10.0.32.0/20"
              next_hop_type          = "VirtualAppliance"
              next_hop_in_ip_address = "10.0.0.4"
            }
            "ADDSVNet-to-Firewall" = {
              address_prefix         = "10.0.16.0/20"
              next_hop_type          = "VirtualAppliance"
              next_hop_in_ip_address = "10.0.0.4"
            }
          }
        }
        "AppGatewaySubnet" = {
          address_prefix = "10.0.3.0/24"
          routes         = null
        }
        "PrivateEndpointSubnet" = {
          address_prefix = "10.0.15.0/24"
          routes         = null
        }
      }
    }
  }

  # Flatten subnets and prepare route table names
  hub_subnets = flatten([
    for vnet_key, vnet in local.hub_vnets : [
      for subnet_name, subnet in vnet.subnets : {
        key              = "${vnet_key}/${subnet_name}"
        vnet_name        = vnet.vnet_name
        subnet_name      = subnet_name
        address_prefix   = subnet.address_prefix
        resource_group   = vnet.resource_group
        location         = vnet.location
        subnet_routes    = subnet.routes
        route_table_name = subnet.routes != null ? "rt-${lower(replace(subnet_name, "Subnet", "sn"))}-${replace(vnet.vnet_name, "vnet-", "")}" : null
      }
    ]
  ])

  # Define Route Tables per VNet
  hub_vnet_route_tables = {
    for vnet_key, vnet in local.hub_vnets :
    "rt-${replace(vnet.vnet_name, "vnet-", "")}" => {
      location            = vnet.location
      resource_group_name = vnet.resource_group
      routes              = vnet.vnet_routes
    }
    if vnet.vnet_routes != null
  }

  # Define Route Tables per Subnet
  hub_subnet_route_tables = {
    for subnet in local.hub_subnets :
    subnet.route_table_name => {
      location            = subnet.location
      resource_group_name = subnet.resource_group
      routes              = subnet.subnet_routes
    }
    if subnet.subnet_routes != null
  }

  # Merge all route tables
  hub_all_route_tables = merge(local.hub_vnet_route_tables, local.hub_subnet_route_tables)
}

# Create Hub Virtual Networks
resource "azurerm_virtual_network" "hub_vnets" {
  for_each = local.hub_vnets

  name                = each.value.vnet_name
  location            = each.value.location
  resource_group_name = each.value.resource_group
  address_space       = each.value.address_space
  dns_servers         = each.value.dns_servers
}

# Create Hub Subnets
resource "azurerm_subnet" "hub_subnets" {
  for_each = { for subnet in local.hub_subnets : subnet.key => subnet }

  name                 = each.value.subnet_name
  address_prefixes     = [each.value.address_prefix]
  resource_group_name  = each.value.resource_group
  virtual_network_name = azurerm_virtual_network.hub_vnets[each.value.vnet_name].name
}

# Create Hub Route Tables
resource "azurerm_route_table" "hub_rt" {
  for_each = local.hub_all_route_tables

  name                = each.key
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  dynamic "route" {
    for_each = [for route_name, route in each.value.routes : merge(route, { name = route_name })]

    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = lookup(route.value, "next_hop_in_ip_address", null)
    }
  }
}

# Associate Route Tables with Hub Subnets
resource "azurerm_subnet_route_table_association" "hub_assoc" {
  for_each = {
    for subnet in local.hub_subnets :
    subnet.key => subnet
    if subnet.route_table_name != null
  }

  subnet_id      = azurerm_subnet.hub_subnets[each.key].id
  route_table_id = azurerm_route_table.hub_rt[each.value.route_table_name].id
}

# Hub NSGs and Associations (if needed)
resource "azurerm_network_security_group" "hub_nsgs" {
  for_each = {
    for subnet in local.hub_subnets :
    subnet.key => subnet
    if var.enable_nsgs && !contains(["AzureFirewallSubnet", "AzureBastionSubnet", "GatewaySubnet", "AppGatewaySubnet"], subnet.subnet_name)
  }

  name                = "nsg-${each.value.vnet_name}-${each.value.subnet_name}"
  location            = each.value.location
  resource_group_name = each.value.resource_group
}

resource "azurerm_subnet_network_security_group_association" "hub_nsg_assoc" {
  for_each = azurerm_network_security_group.hub_nsgs

  subnet_id                 = azurerm_subnet.hub_subnets[each.key].id
  network_security_group_id = each.value.id
}
