output "resource_group_name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.this.name
}

output "vnet_id" {
  description = "ID of the virtual network."
  value       = module.network.vnet_id
}

output "subnet_id" {
  description = "ID of the subnet."
  value       = module.network.subnet_id
}

output "network_security_group_id" {
  description = "ID of the network security group."
  value       = module.security.network_security_group_id
}

output "vm_id" {
  description = "ID of the application VM."
  value       = module.compute.vm_id
}

output "vm_public_ip" {
  description = "Public IP of the VM. Use this in Ansible inventory.ini."
  value       = module.compute.public_ip
}
