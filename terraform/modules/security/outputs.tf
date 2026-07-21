output "network_security_group_id" {
  description = "ID of the application network security group."
  value       = azurerm_network_security_group.app.id
}
