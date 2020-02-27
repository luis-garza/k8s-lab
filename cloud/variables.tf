variable "location" {
  default = "westeurope"
}

variable "network_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  default = "10.0.5.0/24"
}

variable "open_ports" {
  default = [
    { name = "SSH", priority = "100", range = "22" },
    { name = "Traefik", priority = "110", range = "8080" },
    { name = "Kubernetes", priority = "120", range = "6443" }
  ]
}

variable "user" {
  default = {
    id         = "sysop"
    public_key = "~/.ssh/id_rsa_k8s.pub"
  }
}

variable "image" {
  default = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

variable "master" {
  default = {
    count   = 1
    name    = "master"
    size    = "Standard_A2_v2"
    storage = "Standard_LRS"
  }
}

variable "node" {
  default = {
    count   = 2
    name    = "node"
    size    = "Standard_B2s"
    storage = "Standard_LRS"
  }
}

variable "traefik" {
  default = {
    name    = "traefik"
    size    = "Standard_B1ms"
    storage = "Standard_LRS"
  }
}
