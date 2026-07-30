output "vm_id" {
  description = "ID of the application VM."
  value       = azurerm_linux_virtual_machine.app.id
}

output "private_ip" {
  description = "Private IP of the application VM. Ansible targets this via the bastion."
  value       = azurerm_network_interface.this.private_ip_address
}
