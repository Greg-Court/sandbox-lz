locals {
  resource_group_names = {
    hub      = "rg-hub-${var.loc_short}-01"
    identity = "rg-adds-${var.loc_short}-01"
    main     = "rg-main-${var.loc_short}-01"
    mgmt     = "rg-mgmt-${var.loc_short}-01"
  }
}

resource "azurerm_resource_group" "hub" {
  name     = local.resource_group_names.hub
  location = var.loc
}

resource "azurerm_resource_group" "identity" {
  name     = local.resource_group_names.identity
  location = var.loc
}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_names.main
  location = var.loc
}

resource "azurerm_resource_group" "mgmt" {
  name     = local.resource_group_names.mgmt
  location = var.loc
}
