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

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet (bastion host)."
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for the private subnet (application VM)."
  type        = string
  default     = "10.0.2.0/24"
}

variable "db_subnet_cidr" {
  description = "CIDR for the delegated database subnet."
  type        = string
  default     = "10.0.3.0/24"
}

variable "vm_size" {
  description = "Azure VM size for the application host."
  type        = string
}

variable "bastion_vm_size" {
  description = "Azure VM size for the bastion host."
  type        = string
  default     = "Standard_B2ts_v2"
}

variable "app_port" {
  description = "Port the AgriPulse container listens on."
  type        = number
  default     = 3000
}

variable "ssh_ingress_cidrs" {
  description = "Source prefixes allowed to reach the bastion over SSH. Restrict to known admin IPs, e.g. [\"203.0.113.10/32\"]. Required, so SSH is never left open by default."
  type        = list(string)
}

variable "app_ingress_cidr" {
  description = "Source prefix allowed to reach the app port. A CIDR, or \"*\" for any."
  type        = string
  default     = "*"
}

variable "admin_username" {
  description = "Admin username for the Linux VMs."
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Path to the owner's SSH public key, installed on both VMs."
  type        = string
}

variable "extra_ssh_public_keys" {
  description = "Additional SSH public keys (raw key material) granted access, e.g. teammates running Ansible."
  type        = list(string)
  default     = []
}

variable "db_admin_username" {
  description = "PostgreSQL administrator login."
  type        = string
  default     = "psqladmin"
}

variable "db_admin_password" {
  description = "PostgreSQL administrator password. Supply via TF_VAR_db_admin_password, never commit it."
  type        = string
  sensitive   = true
}

variable "db_sku_name" {
  description = "PostgreSQL flexible server SKU (Burstable B1ms is the cheapest managed option)."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "db_storage_mb" {
  description = "PostgreSQL storage in MB (minimum 32768)."
  type        = number
  default     = 32768
}

variable "postgres_version" {
  description = "PostgreSQL major version."
  type        = string
  default     = "16"
}

variable "acr_name" {
  description = "Base name for the container registry (lowercase alphanumeric; a random suffix is appended)."
  type        = string
}

variable "acr_sku" {
  description = "Container registry SKU."
  type        = string
  default     = "Basic"
}
