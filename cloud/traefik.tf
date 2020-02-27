resource "azurerm_public_ip" "traefik" {
  name                = "${local.prefix}-${var.traefik.name}-ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  domain_name_label   = "${local.prefix}-${var.traefik.name}"
}

resource "azurerm_network_interface" "traefik" {
  name                = "${local.prefix}-${var.traefik.name}-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  ip_configuration {
    name                          = "ip"
    subnet_id                     = azurerm_subnet.network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.traefik.id
  }
}

resource "azurerm_linux_virtual_machine" "traefik" {
  name                  = "${local.prefix}-${var.traefik.name}"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = var.traefik.size
  admin_username        = var.user.id
  network_interface_ids = [azurerm_network_interface.traefik.id]
  admin_ssh_key {
    username   = var.user.id
    public_key = file(var.user.public_key)
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.traefik.storage
  }
  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }
}
