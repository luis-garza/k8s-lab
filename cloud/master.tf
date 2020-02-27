resource "azurerm_public_ip" "master" {
  name                = "${local.prefix}-${var.master.name}${count.index + 1}-ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  domain_name_label   = "${local.prefix}-${var.master.name}${count.index + 1}"
  count               = var.master.count
}

resource "azurerm_network_interface" "master" {
  name                = "${local.prefix}-${var.master.name}${count.index + 1}-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  count               = var.master.count
  ip_configuration {
    name                          = "ip"
    subnet_id                     = azurerm_subnet.network.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.master[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "master" {
  name                  = "${local.prefix}-${var.master.name}${count.index + 1}"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = var.master.size
  admin_username        = var.user.id
  network_interface_ids = [azurerm_network_interface.master[count.index].id]
  count                 = var.master.count
  admin_ssh_key {
    username   = var.user.id
    public_key = file(var.user.public_key)
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.master.storage
  }
  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }
}
