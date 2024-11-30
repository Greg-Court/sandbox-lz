resource "random_integer" "st" {
  min = 00
  max = 99
}

data "http" "my_public_ip" {
  url = "https://api.ipify.org?format=text"
}

resource "azurerm_storage_account" "main" {
  name                     = "stmain${var.loc_short}${random_integer.st.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.loc
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = [data.http.my_public_ip.response_body]
    virtual_network_subnet_ids = []
  }
}

resource "azurerm_storage_container" "test" {
  name                  = "test"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

resource "azurerm_storage_share" "test" {
  name               = "test"
  storage_account_id = azurerm_storage_account.main.id
  quota              = 100
}

resource "azurerm_private_endpoint" "blob" {
  name                = "pe-blob-stmain${var.loc_short}${random_integer.st.result}"
  location            = var.loc
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.subnets["vnet-main-${var.loc_short}-01/PrivateEndpointSubnet"].id

  private_service_connection {
    name                           = "psc-stmain${var.loc_short}${random_integer.st.result}"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name = "pdnsg-blob-stmain${var.loc_short}${random_integer.st.result}"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.blob.id
    ]
  }
}

resource "azurerm_private_endpoint" "file" {
  name                = "pe-file-stmain${var.loc_short}${random_integer.st.result}"
  location            = var.loc
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.subnets["vnet-main-${var.loc_short}-01/PrivateEndpointSubnet"].id

  private_service_connection {
    name                           = "psc-stmain${var.loc_short}${random_integer.st.result}"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name = "pdnsg-file-stmain${var.loc_short}${random_integer.st.result}"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.file.id
    ]
  }
}
