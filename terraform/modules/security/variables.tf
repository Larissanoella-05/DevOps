variable "name" {
  description = "Name prefix for security resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the NSGs in."
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet the bastion NSG is associated with."
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet the app NSG is associated with."
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR of the public subnet, used as the allowed source for the private tier."
  type        = string
}

variable "app_port" {
  description = "Application port to allow inbound."
  type        = number
}

variable "ssh_ingress_cidrs" {
  description = "Source address prefixes allowed to reach the bastion over SSH."
  type        = list(string)
}

variable "app_ingress_cidr" {
  description = "Source address prefix allowed to reach the app port on the bastion (a CIDR, or \"*\" for any)."
  type        = string
  default     = "*"
}

variable "tags" {
  description = "Tags applied to security resources."
  type        = map(string)
  default     = {}
}
