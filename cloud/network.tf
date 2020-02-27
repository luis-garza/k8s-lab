resource "azurerm_virtual_network" "network" {
  name                = "${local.prefix}-net"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = [var.network_cidr]
}

resource "azurerm_subnet" "network" {
  name                 = "${local.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefix       = var.subnet_cidr
}

resource "azurerm_network_security_group" "network" {
  name                = "${local.prefix}-ngs"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  dynamic "security_rule" {
    for_each = [for port in var.open_ports : {
      name     = port.name
      priority = port.priority
      range    = port.range
    }]
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "TCP"
      source_port_range          = "*"
      destination_port_range     = security_rule.value.range
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "network" {
  subnet_id                 = azurerm_subnet.network.id
  network_security_group_id = azurerm_network_security_group.network.id
}
