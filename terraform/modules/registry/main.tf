# Private container registry. The CD pipeline pushes the app image here and the
# app VM pulls from it. Admin user is enabled so the pipeline can `docker login`
# with credentials stored as GitHub secrets.

resource "azurerm_container_registry" "this" {
  name                = "${var.name}${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = true

  tags = var.tags
}
