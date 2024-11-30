locals {
  appgw_name                      = "appgw-hub-${var.loc_short}-01"
  appgw_public_ip_name            = "pip-appgw-hub-${var.loc_short}-01"
  frontend_port_name              = "frontendPort"
  frontend_ip_configuration_name  = "frontendIP"
  backend_address_pool_name       = "backendPool"
  http_setting_name               = "backendHttpSettings"
  listener_name                   = "httpListener"
  request_routing_rule_name       = "routingRule"
  gateway_ip_configuration_name   = "appgw-ip-configuration"
}

resource "azurerm_public_ip" "appgw" {
  name                = local.appgw_public_ip_name
  location            = var.loc
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = local.appgw_name
  location            = var.loc
  resource_group_name = azurerm_resource_group.hub.name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = local.gateway_ip_configuration_name
    subnet_id = azurerm_subnet.hub_subnets["vnet-hub-${var.loc_short}-01/AppGatewaySubnet"].id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = azurerm_public_ip.appgw.name
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name         = local.backend_address_pool_name
    ip_addresses = [azurerm_network_interface.nics["vm-ws22-${var.loc_short}-01"].ip_configuration[0].private_ip_address]
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  tags = {
    environment = "dev"
  }
}


