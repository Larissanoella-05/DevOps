variable "name" {
  description = "Base name for the registry (alphanumeric; a random suffix is appended for global uniqueness)."
  type        = string
}

variable "name_suffix" {
  description = "Random suffix appended to the registry name to keep it globally unique."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the registry in."
  type        = string
}

variable "sku" {
  description = "Registry SKU (Basic is the cheapest and enough for one app image)."
  type        = string
  default     = "Basic"
}

variable "tags" {
  description = "Tags applied to the registry."
  type        = map(string)
  default     = {}
}
