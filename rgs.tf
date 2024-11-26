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


# # To implement later:
# locals {
#   resource_groups = {
#     hub = {
#       name = "rg-hub-${var.loc_short}-01"
#     }
#     identity = {
#       name = "rg-adds-${var.loc_short}-01"
#     }
#     main = {
#       name = "rg-main-${var.loc_short}-01"
#     }
#     mgmt = {
#       name = "rg-mgmt-${var.loc_short}-01"
#     }
#   }
# }

# resource "azurerm_resource_group" "rgs" {
#   for_each = local.resource_groups

#   name     = each.value.name
#   location = var.loc
# }