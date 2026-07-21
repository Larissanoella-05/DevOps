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

variable "ssh_ingress_cidrs" {
  description = "Source prefixes allowed to reach SSH (port 22). Restrict to known admin IPs, e.g. [\"203.0.113.10/32\"]. Required, so SSH is never left open by default."
  type        = list(string)
}

variable "app_ingress_cidr" {
  description = "Source prefix allowed to reach the app port. A CIDR, or \"*\" for any."
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

variable "extra_ssh_public_keys" {
  description = "Additional SSH public keys (raw key material) granted access to the VM, e.g. teammates running Ansible."
  type        = list(string)
  default     = []
}
