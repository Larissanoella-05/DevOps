variable "name" {
  description = "Name prefix for security resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the NSG in."
  type        = string
}

variable "subnet_id" {
  description = "Subnet the NSG is associated with."
  type        = string
}

variable "app_port" {
  description = "Application port to allow inbound."
  type        = number
}

variable "ssh_ingress_cidr" {
  description = "Source address prefix allowed to reach SSH (a CIDR, or \"*\" for any)."
  type        = string
}

variable "tags" {
  description = "Tags applied to security resources."
  type        = map(string)
  default     = {}
}
