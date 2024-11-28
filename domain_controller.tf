locals {
  domain_controller_ip = "10.0.16.4"
  addc_script_base64 = base64encode(templatefile("${path.module}/addc_script.ps1", {
    username                = var.admin_username,
    password                = var.admin_password,
    active_directory_domain = var.active_directory_domain
    firewall_private_ip     = azurerm_firewall.primary.ip_configuration[0].private_ip_address
  }))
}

resource "azurerm_virtual_machine_extension" "dc_extension" {
  name                 = "DomainControllerExtension"
  virtual_machine_id   = azurerm_windows_virtual_machine.vms["vm-dc-${var.loc_short}-01"].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  protected_settings = <<SETTINGS
  {
    "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${local.addc_script_base64}')) | Out-File -filepath dc_setup.ps1\" && powershell -ExecutionPolicy Unrestricted -File dc_setup.ps1"
  }
  SETTINGS
}

# output "decoded_script" {
#   value = base64decode(local.addc_script_base64)
# }