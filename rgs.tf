resource "azurerm_resource_group" "hub" {
  name     = "rg-hub-${var.loc_short}-01"
  location = var.loc
}

resource "azurerm_resource_group" "identity" {
  name     = "rg-adds-${var.loc_short}-01"
  location = var.loc
}

resource "azurerm_resource_group" "main" {
  name     = "rg-main-${var.loc_short}-01"
  location = var.loc
}

resource "azurerm_resource_group" "mgmt" {
  name     = "rg-mgmt-${var.loc_short}-01"
  location = var.loc
}