variable "name" {
  description = "Name prefix for network resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the network in."
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR block for the virtual network."
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet (bastion host)."
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR for the private subnet (application VM)."
  type        = string
}

variable "db_subnet_cidr" {
  description = "CIDR for the delegated database subnet."
  type        = string
}

variable "tags" {
  description = "Tags applied to network resources."
  type        = map(string)
  default     = {}
}
