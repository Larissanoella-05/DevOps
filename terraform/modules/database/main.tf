# Managed PostgreSQL, reachable only from inside the VNet (no public endpoint).
# A private DNS zone resolves the server's FQDN for hosts on the network.

resource "azurerm_private_dns_zone" "postgres" {
  name                = "${var.name}.private.postgres.database.azure.com"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "${var.name}-postgres-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = var.vnet_id

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                = "${var.name}-psql-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = var.postgres_version

  delegated_subnet_id           = var.delegated_subnet_id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false

  administrator_login    = var.admin_username
  administrator_password = var.admin_password

  sku_name   = var.sku_name
  storage_mb = var.storage_mb

  tags = var.tags

  # The DNS link must exist before the server attaches to the private zone.
  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}
