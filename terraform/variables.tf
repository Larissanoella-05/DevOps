variable "project_name" {
  description = "Project name used as a prefix for resource names and tags."
  type        = string
  default     = "agripulse"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region to deploy into."
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR block for the virtual network."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet the VM lives in."
  type        = string
  default     = "10.0.1.0/24"
}

variable "vm_size" {
  description = "Azure VM size for the application server."
  type        = string
}

variable "app_port" {
  description = "Port the AgriPulse container listens on."
  type        = number
  default     = 3000
}

variable "ssh_ingress_cidr" {
  description = "Source prefix allowed to reach SSH (port 22). A CIDR, or \"*\" for any. Restrict this in production."
  type        = string
  default     = "*"
}

variable "admin_username" {
  description = "Admin username for the Linux VM."
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key uploaded to the VM for admin access."
  type        = string
}
