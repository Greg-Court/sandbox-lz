locals {
  custom_hub_nsg_rules = {
    "vnet-hub-uks-01/AppGatewaySubnet" = {
      rules = {
        "TestAppGwNSGRule" = {
          priority                   = 1000
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "10"
          source_address_prefix      = "10.0.0.10"
          destination_address_prefix = "10.0.0.10"
        }
      }
    }
  }
  custom_hub_nsg_rules_flat = flatten([
    for subnet_key, subnet_data in local.custom_hub_nsg_rules : [
      for rule_name, rule in subnet_data.rules : {
        subnet_key = subnet_key
        rule_name  = rule_name
        rule       = rule
      }
    ]
  ])
}


resource "azurerm_network_security_rule" "custom_hub_nsg_rules" {
  for_each = {
    for rule in local.custom_hub_nsg_rules_flat :
    "${rule.subnet_key}-${rule.rule_name}" => rule
  }

  name                        = each.value.rule_name
  resource_group_name         = azurerm_network_security_group.hub_nsgs[each.value.subnet_key].resource_group_name
  network_security_group_name = azurerm_network_security_group.hub_nsgs[each.value.subnet_key].name

  priority                   = each.value.rule.priority
  direction                  = each.value.rule.direction
  access                     = each.value.rule.access
  protocol                   = each.value.rule.protocol
  source_port_range          = each.value.rule.source_port_range
  destination_port_range     = each.value.rule.destination_port_range
  source_address_prefix      = each.value.rule.source_address_prefix
  destination_address_prefix = each.value.rule.destination_address_prefix
}