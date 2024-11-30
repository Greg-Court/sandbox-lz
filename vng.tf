# Public IP for Virtual Network Gateway
resource "azurerm_public_ip" "vng_pip" {
  name                = "pip-vng-hub-${var.loc_short}-01"
  location            = var.loc
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Virtual Network Gateway
resource "azurerm_virtual_network_gateway" "vng" {
  count               = var.deploy_vng ? 1 : 0
  name                = "vng-hub-${var.loc_short}-01"
  location            = var.loc
  resource_group_name = azurerm_resource_group.hub.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    name                 = "vng-ipconfig"
    public_ip_address_id = azurerm_public_ip.vng_pip.id
    subnet_id            = azurerm_subnet.hub_subnets["vnet-hub-${var.loc_short}-01/GatewaySubnet"].id
  }
}

data "http" "my_public_ip2" {
  url = "https://api.ipify.org?format=text"
}

# Local Network Gateway
resource "azurerm_local_network_gateway" "lng" {
  count               = var.deploy_vng ? 1 : 0
  name                = "lng-greghome-${var.loc_short}-01"
  location            = var.loc
  resource_group_name = azurerm_resource_group.hub.name

  gateway_address = data.http.my_public_ip2.response_body
  address_space   = var.lng_address_space
}

# VPN Connection
resource "azurerm_virtual_network_gateway_connection" "vpn_connection" {
  count                      = var.deploy_vng ? 1 : 0
  name                       = "vpn-connection-${var.loc_short}-01"
  location                   = var.loc
  resource_group_name        = azurerm_resource_group.hub.name
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vng[0].id
  local_network_gateway_id   = azurerm_local_network_gateway.lng[0].id
  type                       = "IPsec"
  connection_mode            = "Default"
  connection_protocol        = "IKEv2"
  shared_key                 = var.vpn_psk
  dpd_timeout_seconds        = 45
  # see https://registry.terraform.io/providers/hashicorp/Azurerm/latest/docs/resources/virtual_network_gateway_connection#connection_protocol-1
  ipsec_policy {
    dh_group         = "DHGroup14"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    pfs_group        = "PFS2048"
    sa_datasize      = "0"
    sa_lifetime      = "3600"
  }
}

# Output for Public IP
output "vng_public_ip" {
  value = var.deploy_vng && length(azurerm_public_ip.vng_pip) > 0 ? azurerm_public_ip.vng_pip.ip_address : null # Safeguard with conditional
}