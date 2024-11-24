output "firewall_public_ip" {
  description = "Public IP address of the Azure Firewall."
  value       = azurerm_public_ip.firewall_pip.ip_address
}