provider "azurerm" {
  version = "~> 2.0"
  features {}
}

provider "template" {
  version = "~> 2.1"
}

provider "local" {
  version = "~> 1.4"

}

terraform {
  backend "azurerm" {
    resource_group_name  = "miscellany"
    storage_account_name = "miscellany"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

locals {
  prefix = terraform.workspace
}

resource "azurerm_resource_group" "main" {
  name     = local.prefix
  location = var.location
}

data "template_file" "inventory" {
  template = file("./templates/inventory.tpl")
  vars = {
    master  = join("\n", azurerm_public_ip.master.*.fqdn)
    node    = join("\n", azurerm_public_ip.node.*.fqdn)
    traefik = azurerm_public_ip.traefik.fqdn
    user    = var.user.id
    cidr    = var.subnet_cidr
  }
}

resource "local_file" "inventory" {
  content  = data.template_file.inventory.rendered
  filename = "../out/inventory/${local.prefix}"
}
