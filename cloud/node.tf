resource "azurerm_public_ip" "node" {
  name                = "${local.prefix}-${var.node.name}${count.index + 1}-ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  domain_name_label   = "${local.prefix}-${var.node.name}${count.index + 1}"
  count               = var.node.count
}

resource "azurerm_network_interface" "node" {
  name                = "${local.prefix}-${var.node.name}${count.index + 1}-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  count               = var.node.count
  ip_configuration {
    name                          = "ip"
    subnet_id                     = azurerm_subnet.network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.node[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "node" {
  name                  = "${local.prefix}-${var.node.name}${count.index + 1}"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = var.node.size
  admin_username        = var.user.id
  network_interface_ids = [azurerm_network_interface.node[count.index].id]
  count                 = var.node.count
  admin_ssh_key {
    username   = var.user.id
    public_key = file(var.user.public_key)
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.node.storage
  }
  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }
}
