variable "name" {
  description = "Name prefix for security resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC the security group is created in."
  type        = string
}

variable "app_port" {
  description = "Application port to allow inbound."
  type        = number
}

variable "ssh_ingress_cidr" {
  description = "CIDR range allowed to reach SSH. Restrict this in production."
  type        = string
}
