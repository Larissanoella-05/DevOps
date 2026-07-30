output "server_name" {
  description = "Name of the PostgreSQL flexible server."
  value       = azurerm_postgresql_flexible_server.this.name
}

output "server_fqdn" {
  description = "Private FQDN the app connects to (resolvable inside the VNet)."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "server_id" {
  description = "Resource ID of the PostgreSQL flexible server."
  value       = azurerm_postgresql_flexible_server.this.id
}
