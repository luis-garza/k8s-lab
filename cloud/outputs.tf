output "masters" {
  value = azurerm_public_ip.master.*.fqdn
}

output "nodes" {
  value = azurerm_public_ip.node.*.fqdn
}

output "traefik" {
  value = azurerm_public_ip.traefik.fqdn
}
