resource "azurerm_private_dns_resolver" "hub" {
  name                = "dnspr-hub-uks-01"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  virtual_network_id  = azurerm_virtual_network.hub_vnets["vnet-hub-uks-01"].id
}

# mandatory outbound DNS endpoint
resource "azurerm_private_dns_resolver_outbound_endpoint" "hub_out" {
  name                    = "out-hub-uks-01"
  location                = azurerm_resource_group.hub.location
  private_dns_resolver_id = azurerm_private_dns_resolver.hub.id
  subnet_id               = azurerm_subnet.hub_subnets["vnet-hub-uks-01/ADPROutboundSubnet"].id
}

# dnsfrs
resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "azure_dns" {
  name                                       = "dnsfrs-azure-uks-01"
  resource_group_name                        = azurerm_resource_group.hub.name
  location                                   = azurerm_resource_group.hub.location
  private_dns_resolver_outbound_endpoint_ids = [azurerm_private_dns_resolver_outbound_endpoint.hub_out.id]
  tags = {
    key = "value"
  }
}

resource "azurerm_private_dns_resolver_virtual_network_link" "main" {
  name                  = "link-vnet-main-uks-01"
  virtual_network_id    = azurerm_virtual_network.spoke_vnets["vnet-main-uks-01"].id
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.azure_dns.id
}

resource "azurerm_private_dns_resolver_virtual_network_link" "adds" {
  name                  = "link-vnet-adds-uks-01"
  virtual_network_id    = azurerm_virtual_network.spoke_vnets["vnet-adds-uks-01"].id
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.azure_dns.id
}

resource "azurerm_private_dns_resolver_virtual_network_link" "hub" {
  name                  = "link-vnet-hub-uks-01"
  virtual_network_id    = azurerm_virtual_network.hub_vnets["vnet-hub-uks-01"].id
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.azure_dns.id
}