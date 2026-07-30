# Two network security groups, one per tier. Azure adds an implicit DenyAllInbound
# rule at the lowest priority, so anything not explicitly allowed here is blocked.
#
#   bastion (public)  — SSH from admin IPs; app port from the internet (reverse proxy)
#   app     (private) — SSH and app traffic only from the bastion subnet

resource "azurerm_network_security_group" "bastion" {
  name                = "${var.name}-bastion-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "allow-ssh"
    description                = "SSH from admin IPs"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.ssh_ingress_cidrs
    destination_address_prefix = "*"
  }

  security_rule {
    name                   = "allow-app"
    description            = "Public web traffic to the app, proxied to the private VM"
    priority               = 1002
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_port_range      = "*"
    destination_port_range = tostring(var.app_port)
    # AgriPulse is a public web app, so this port is meant to be internet-reachable.
    # SSH stays restricted to admin IPs above. Documented in SECURITY.md.
    # tfsec:ignore:azure-network-no-public-ingress
    source_address_prefix      = var.app_ingress_cidr
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_network_security_group" "app" {
  name                = "${var.name}-app-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "allow-ssh-from-bastion"
    description                = "SSH only from the bastion subnet"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.public_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-app-from-bastion"
    description                = "App traffic only from the bastion subnet"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.app_port)
    source_address_prefix      = var.public_subnet_cidr
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = var.public_subnet_id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = var.private_subnet_id
  network_security_group_id = azurerm_network_security_group.app.id
}
