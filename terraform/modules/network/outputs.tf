output "vnet_id" {
  description = "ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "public_subnet_id" {
  description = "ID of the public (bastion) subnet."
  value       = azurerm_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private (application) subnet."
  value       = azurerm_subnet.private.id
}

output "database_subnet_id" {
  description = "ID of the delegated database subnet."
  value       = azurerm_subnet.database.id
}
