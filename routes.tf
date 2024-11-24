locals {
  route_tables = {
    "rt-hub-${var.loc_short}-01" = {
      resource_group_name = azurerm_resource_group.hub.name
      routes = [
        {
          name                   = "MainVNet-to-Firewall"
          address_prefix         = tolist(azurerm_virtual_network.vnets["vnet-main-${var.loc_short}-01"].address_space)[0]
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = azurerm_firewall.primary.ip_configuration[0].private_ip_address
        },
        {
          name                   = "ADDSVNet-to-Firewall"
          address_prefix         = tolist(azurerm_virtual_network.vnets["vnet-adds-${var.loc_short}-01"].address_space)[0]
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = azurerm_firewall.primary.ip_configuration[0].private_ip_address
        },
      ]
      associations = [
        {
          vnet_name   = "vnet-hub-${var.loc_short}-01"
          subnet_name = "GatewaySubnet"
        },
      ]
    }
    "rt-adds-${var.loc_short}-01" = {
      resource_group_name = azurerm_resource_group.identity.name
      routes = [
        {
          name                   = "Internet-to-Firewall"
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = azurerm_firewall.primary.ip_configuration[0].private_ip_address
        },
        {
          name                   = "VNetLocal-to-Firewall"
          address_prefix         = tolist(azurerm_virtual_network.vnets["vnet-adds-${var.loc_short}-01"].address_space)[0]
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = azurerm_firewall.primary.ip_configuration[0].private_ip_address
        },
      ]
      associations = [
        {
          vnet_name   = "vnet-adds-${var.loc_short}-01"
          subnet_name = "ADDSSubnet"
        }
      ]
    }
    "rt-main-${var.loc_short}-01" = {
      resource_group_name = azurerm_resource_group.main.name
      routes = [
        {
          name                   = "Internet-to-Firewall"
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = azurerm_firewall.primary.ip_configuration[0].private_ip_address
        },
        {
          name                   = "VNetLocal-to-Firewall"
          address_prefix         = tolist(azurerm_virtual_network.vnets["vnet-main-${var.loc_short}-01"].address_space)[0]
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = azurerm_firewall.primary.ip_configuration[0].private_ip_address
        },
      ]
      associations = [
        {
          vnet_name   = "vnet-main-${var.loc_short}-01"
          subnet_name = "VM1Subnet"
        },
        {
          vnet_name   = "vnet-main-${var.loc_short}-01"
          subnet_name = "VM2Subnet"
        }
      ]
    }
  }
  routes = flatten([
    for rt_name, rt in local.route_tables : [
      for route in rt.routes : merge(
        route,
        {
          route_table_name    = rt_name
          resource_group_name = rt.resource_group_name
        }
      )
    ]
  ])
  associations = flatten([
    for rt_name, rt in local.route_tables : [
      for assoc in rt.associations : merge(
        assoc,
        {
          route_table_name = rt_name
        }
      )
    ]
  ])
}

resource "azurerm_route_table" "route_tables" {
  for_each = local.route_tables

  name                = each.key
  location            = var.loc
  resource_group_name = each.value.resource_group_name
}

resource "azurerm_route" "routes" {
  for_each = {
    for route in local.routes :
    "${route.route_table_name}/${route.name}" => route
  }

  name                   = each.value.name
  resource_group_name    = each.value.resource_group_name
  route_table_name       = azurerm_route_table.route_tables[each.value.route_table_name].name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address
}

resource "azurerm_subnet_route_table_association" "associations" {
  for_each = {
    for assoc in local.associations :
    "${assoc.route_table_name}-${assoc.vnet_name}/${assoc.subnet_name}" => assoc
  }

  subnet_id      = azurerm_subnet.subnets["${each.value.vnet_name}/${each.value.subnet_name}"].id
  route_table_id = azurerm_route_table.route_tables[each.value.route_table_name].id
}
