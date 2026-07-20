output "vm_id" {
  description = "ID of the application VM."
  value       = azurerm_linux_virtual_machine.app.id
}

output "public_ip" {
  description = "Public IP address of the application VM."
  value       = azurerm_public_ip.this.ip_address
}
