variable "name" {
  description = "Name prefix for bastion resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the bastion in."
  type        = string
}

variable "subnet_id" {
  description = "Public subnet the bastion's NIC is attached to."
  type        = string
}

variable "vm_size" {
  description = "Azure VM size for the bastion (small is fine; it only forwards traffic)."
  type        = string
}

variable "admin_username" {
  description = "Admin username for the bastion."
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_keys" {
  description = "SSH public keys installed on the bastion (owner key plus any teammate keys)."
  type        = list(string)
}

variable "image_publisher" {
  description = "Publisher of the base image."
  type        = string
  default     = "Canonical"
}

variable "image_offer" {
  description = "Offer of the base image."
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "image_sku" {
  description = "SKU of the base image (Ubuntu 22.04 LTS)."
  type        = string
  default     = "22_04-lts-gen2"
}

variable "tags" {
  description = "Tags applied to bastion resources."
  type        = map(string)
  default     = {}
}
