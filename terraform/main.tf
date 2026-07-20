terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state — enable once the S3 bucket and lock table exist.
  # See README.md ("Remote state") for the one-time bootstrap.
  # backend "s3" {
  #   bucket         = "agripulse-tfstate"
  #   key            = "f3/terraform.tfstate"
  #   region         = "eu-west-1"
  #   dynamodb_table = "agripulse-tf-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

locals {
  name = "${var.project_name}-${var.environment}"
}

module "network" {
  source      = "./modules/network"
  name        = local.name
  vpc_cidr    = var.vpc_cidr
  subnet_cidr = var.subnet_cidr
}

module "security" {
  source           = "./modules/security"
  name             = local.name
  vpc_id           = module.network.vpc_id
  app_port         = var.app_port
  ssh_ingress_cidr = var.ssh_ingress_cidr
}

module "compute" {
  source              = "./modules/compute"
  name                = local.name
  subnet_id           = module.network.subnet_id
  security_group_id   = module.security.security_group_id
  instance_type       = var.instance_type
  ssh_public_key_path = var.ssh_public_key_path
}
