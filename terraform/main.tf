terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Remote state, in a storage account bootstrapped outside Terraform (see
  # README.md "Remote state" for that one-time setup — Terraform can't
  # create the backend that stores its own state). Workspaces (dev/staging/
  # prod) are handled automatically: azurerm prefixes each workspace's
  # blob with "env:<workspace>" within this same container.
  backend "azurerm" {
    resource_group_name  = "agripulse-tfstate-rg"
    storage_account_name = "agripulsetfstate"
    container_name       = "tfstate"
    key                  = "summative.terraform.tfstate"
  }
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

  # Every key installed on the VMs: the owner's key plus any teammate keys. Read
  # once here so the modules just take a plain list.
  ssh_public_keys = concat(
    [file(pathexpand(var.ssh_public_key_path))],
    var.extra_ssh_public_keys,
  )
}

# Short suffix to keep globally-unique names (registry, database) collision-free.
resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
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
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  db_subnet_cidr      = var.db_subnet_cidr
  tags                = local.tags
}

module "security" {
  source              = "./modules/security"
  name                = local.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  public_subnet_id    = module.network.public_subnet_id
  private_subnet_id   = module.network.private_subnet_id
  public_subnet_cidr  = var.public_subnet_cidr
  app_port            = var.app_port
  ssh_ingress_cidrs   = var.ssh_ingress_cidrs
  app_ingress_cidr    = var.app_ingress_cidr
  tags                = local.tags
}

module "registry" {
  source              = "./modules/registry"
  name                = var.acr_name
  name_suffix         = random_string.suffix.result
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = var.acr_sku
  tags                = local.tags
}

module "database" {
  source              = "./modules/database"
  name                = local.name
  name_suffix         = random_string.suffix.result
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  vnet_id             = module.network.vnet_id
  delegated_subnet_id = module.network.database_subnet_id
  admin_username      = var.db_admin_username
  admin_password      = var.db_admin_password
  sku_name            = var.db_sku_name
  storage_mb          = var.db_storage_mb
  postgres_version    = var.postgres_version
  tags                = local.tags
}

module "bastion" {
  source              = "./modules/bastion"
  name                = local.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.network.public_subnet_id
  vm_size             = var.bastion_vm_size
  admin_username      = var.admin_username
  ssh_public_keys     = local.ssh_public_keys
  tags                = local.tags
}

module "compute" {
  source              = "./modules/compute"
  name                = local.name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.network.private_subnet_id
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  ssh_public_keys     = local.ssh_public_keys
  tags                = local.tags
}
