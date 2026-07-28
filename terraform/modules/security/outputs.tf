output "bastion_nsg_id" {
  description = "ID of the bastion network security group."
  value       = azurerm_network_security_group.bastion.id
}

output "app_nsg_id" {
  description = "ID of the application network security group."
  value       = azurerm_network_security_group.app.id
}
