locals {
  windows_vms = {
    # "vm-dc-${var.loc_short}-01" = {
    #   vnet_name          = "vnet-adds-${var.loc_short}-01"
    #   rg_name            = azurerm_resource_group.identity.name
    #   subnet_name        = "ADDSSubnet"
    #   private_ip_address = local.domain_controller_ip
    #   os                 = "WS22"
    # },
    # "vm-ws22-${var.loc_short}-01" = {
    #   vnet_name   = "vnet-main-${var.loc_short}-01"
    #   rg_name     = azurerm_resource_group.main.name
    #   subnet_name = "WindowsSubnet"
    #   os          = "WS22"
    # }
  }
  linux_vms = {
    "vm-ubu24-${var.loc_short}-01" = {
      vnet_name   = "vnet-main-${var.loc_short}-01"
      rg_name     = azurerm_resource_group.main.name
      subnet_name = "LinuxSubnet"
      os          = "UBU24"
    }
  }

  source_image_reference_library = {
    WS22 = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-Datacenter"
      version   = "latest"
    }
    UBU24 = {
      publisher = "Canonical"
      offer     = "ubuntu-24_04-lts"
      sku       = "server"
      version   = "latest"
    }
  }
}

resource "azurerm_network_interface" "nics" {
  for_each = merge(local.windows_vms, local.linux_vms)

  name                = "nic-${each.key}"
  location            = var.loc
  resource_group_name = each.value.rg_name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.spoke_subnets["${each.value.vnet_name}/${each.value.subnet_name}"].id
    private_ip_address_allocation = "Dynamic"
  }
}

# Virtual Machines
resource "azurerm_windows_virtual_machine" "vms" {
  for_each = { for k, v in azurerm_network_interface.nics : k => v if contains(keys(local.windows_vms), k) }

  name                              = each.key
  resource_group_name               = local.windows_vms[each.key].rg_name
  location                          = var.loc
  size                              = "Standard_B2ms"
  admin_username                    = var.admin_username
  admin_password                    = var.admin_password
  network_interface_ids             = [each.value.id]
  vm_agent_platform_updates_enabled = true
  patch_mode                        = "AutomaticByPlatform"

  os_disk {
    name                 = "osdisk-${each.key}"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = local.source_image_reference_library[local.windows_vms[each.key].os].publisher
    offer     = local.source_image_reference_library[local.windows_vms[each.key].os].offer
    sku       = local.source_image_reference_library[local.windows_vms[each.key].os].sku
    version   = local.source_image_reference_library[local.windows_vms[each.key].os].version
  }

  boot_diagnostics {
    storage_account_uri = null
  }

  lifecycle {
    ignore_changes = [
      vm_agent_platform_updates_enabled
    ]
  }
}

resource "azurerm_linux_virtual_machine" "vms" {
  for_each = { for k, v in azurerm_network_interface.nics : k => v if contains(keys(local.linux_vms), k) }

  name                              = each.key
  resource_group_name               = local.linux_vms[each.key].rg_name
  location                          = var.loc
  size                              = "Standard_B2ms"
  disable_password_authentication   = false
  admin_username                    = var.admin_username
  admin_password                    = var.admin_password
  network_interface_ids             = [each.value.id]
  vm_agent_platform_updates_enabled = true

  os_disk {
    name                 = "osdisk-${each.key}"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = local.source_image_reference_library[local.linux_vms[each.key].os].publisher
    offer     = local.source_image_reference_library[local.linux_vms[each.key].os].offer
    sku       = local.source_image_reference_library[local.linux_vms[each.key].os].sku
    version   = local.source_image_reference_library[local.linux_vms[each.key].os].version
  }

  boot_diagnostics {
    storage_account_uri = null
  }

  lifecycle {
    ignore_changes = [
      vm_agent_platform_updates_enabled
    ]
  }
}
