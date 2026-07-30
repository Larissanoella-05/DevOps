output "login_server" {
  description = "Registry hostname the CD pipeline pushes to and the VM pulls from."
  value       = azurerm_container_registry.this.login_server
}

output "admin_username" {
  description = "Admin username for docker login."
  value       = azurerm_container_registry.this.admin_username
}

output "admin_password" {
  description = "Admin password for docker login."
  value       = azurerm_container_registry.this.admin_password
  sensitive   = true
}

output "registry_id" {
  description = "Resource ID of the container registry."
  value       = azurerm_container_registry.this.id
}
