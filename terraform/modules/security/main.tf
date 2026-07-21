# Network security group: allow SSH (22) and the app port inbound, deny the rest.
# Azure adds an implicit DenyAllInbound rule at the lowest priority, so anything
# not explicitly allowed here is blocked.

resource "azurerm_network_security_group" "app" {
  name                = "${var.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "allow-ssh"
    description                = "SSH access"
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
    description            = "AgriPulse app"
    priority               = 1002
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_port_range      = "*"
    destination_port_range = tostring(var.app_port)
    # AgriPulse is a public web app; this port is meant to be internet-reachable.
    # SSH (the sensitive port) is restricted to admin IPs above. See SECURITY.md.
    # tfsec:ignore:azure-network-no-public-ingress
    source_address_prefix      = var.app_ingress_cidr
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.app.id
}
