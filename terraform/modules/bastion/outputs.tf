output "vm_id" {
  description = "ID of the bastion VM."
  value       = azurerm_linux_virtual_machine.bastion.id
}

output "public_ip" {
  description = "Public IP of the bastion. SSH entry point and public app URL."
  value       = azurerm_public_ip.this.ip_address
}

output "private_ip" {
  description = "Private IP of the bastion inside the VNet."
  value       = azurerm_network_interface.this.private_ip_address
}
