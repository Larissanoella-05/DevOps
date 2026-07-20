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

variable "region" {
  description = "Cloud region to deploy into."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet the VM lives in."
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "Compute instance size for the application VM."
  type        = string
}

variable "app_port" {
  description = "Port the AgriPulse container listens on."
  type        = number
  default     = 3000
}

variable "ssh_ingress_cidr" {
  description = "CIDR range allowed to reach SSH (port 22). Restrict this in production."
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key uploaded to the VM for admin access."
  type        = string
}
