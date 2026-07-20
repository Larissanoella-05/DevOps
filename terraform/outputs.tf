output "vpc_id" {
  description = "ID of the VPC."
  value       = module.network.vpc_id
}

output "subnet_id" {
  description = "ID of the public subnet."
  value       = module.network.subnet_id
}

output "security_group_id" {
  description = "ID of the application security group."
  value       = module.security.security_group_id
}

output "instance_id" {
  description = "ID of the application VM."
  value       = module.compute.instance_id
}

output "vm_public_ip" {
  description = "Public IP of the VM. Use this in Ansible inventory.ini."
  value       = module.compute.public_ip
}
