terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Remote state — enable once the storage account and container exist.
  # See README.md ("Remote state") for the one-time bootstrap.
  # backend "azurerm" {
  #   resource_group_name  = "agripulse-tfstate-rg"
  #   storage_account_name = "agripulsetfstate"
  #   container_name       = "tfstate"
  #   key                  = "f3.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
}

locals {
  name = "${var.project_name}-${var.environment}"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "azurerm_resource_group" "this" {
  name     = "${local.name}-rg"
  location = var.location
  tags     = local.tags
}

module "network" {
  source              = "./modules/network"
  name                = local.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  vnet_cidr           = var.vnet_cidr
  subnet_cidr         = var.subnet_cidr
  tags                = local.tags
}

module "security" {
  source              = "./modules/security"
  name                = local.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.network.subnet_id
  app_port            = var.app_port
  ssh_ingress_cidr    = var.ssh_ingress_cidr
  tags                = local.tags
}

module "compute" {
  source              = "./modules/compute"
  name                = local.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.network.subnet_id
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  ssh_public_key_path = var.ssh_public_key_path
  tags                = local.tags
}
