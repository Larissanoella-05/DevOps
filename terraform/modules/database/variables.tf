variable "name" {
  description = "Name prefix for database resources."
  type        = string
}

variable "name_suffix" {
  description = "Random suffix appended to the server name to keep it globally unique."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the database in."
  type        = string
}

variable "vnet_id" {
  description = "VNet the private DNS zone is linked to."
  type        = string
}

variable "delegated_subnet_id" {
  description = "Delegated subnet the flexible server is injected into."
  type        = string
}

variable "admin_username" {
  description = "PostgreSQL administrator login."
  type        = string
}

variable "admin_password" {
  description = "PostgreSQL administrator password. Supplied at apply time, never committed."
  type        = string
  sensitive   = true
}

variable "sku_name" {
  description = "Flexible server SKU. Burstable B1ms is the cheapest managed option."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "storage_mb" {
  description = "Storage allocated to the server, in MB (minimum 32768)."
  type        = number
  default     = 32768
}

variable "postgres_version" {
  description = "PostgreSQL major version."
  type        = string
  default     = "16"
}

variable "tags" {
  description = "Tags applied to database resources."
  type        = map(string)
  default     = {}
}
