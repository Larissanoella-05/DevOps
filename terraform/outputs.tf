output "resource_group_name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.this.name
}

output "bastion_public_ip" {
  description = "Public IP of the bastion. SSH entry point and public app URL."
  value       = module.bastion.public_ip
}

output "app_private_ip" {
  description = "Private IP of the app VM. Put this in Ansible's inventory (reached via the bastion)."
  value       = module.compute.private_ip
}

output "acr_login_server" {
  description = "Container registry hostname the CD pipeline pushes to."
  value       = module.registry.login_server
}

output "acr_admin_username" {
  description = "Container registry admin username for docker login."
  value       = module.registry.admin_username
}

output "acr_admin_password" {
  description = "Container registry admin password for docker login."
  value       = module.registry.admin_password
  sensitive   = true
}

output "database_fqdn" {
  description = "Private FQDN of the PostgreSQL server (resolvable inside the VNet)."
  value       = module.database.server_fqdn
}

output "vnet_id" {
  description = "ID of the virtual network."
  value       = module.network.vnet_id
}
