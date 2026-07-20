variable "name" {
  description = "Name prefix for compute resources."
  type        = string
}

variable "subnet_id" {
  description = "Subnet the VM is launched in."
  type        = string
}

variable "security_group_id" {
  description = "Security group attached to the VM."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the VM."
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key installed on the VM."
  type        = string
}

variable "ami_name_filter" {
  description = "Name pattern used to find the base image (AMI)."
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "ami_owner" {
  description = "AWS account that owns the base image (099720109477 = Canonical)."
  type        = string
  default     = "099720109477"
}
