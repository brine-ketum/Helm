# Output the public IP of the vPacketStack VM for management/SSH access
output "vpacketstack_public_ip" {
  value = azurerm_public_ip.vpacketstack_public_ip.ip_address
}

# Output the public IP of the Platform Load Balancer (PLB)
output "plb_public_ip" {
  value = azurerm_public_ip.plb_public_ip.ip_address
}

# Output the backend pool ID of the Platform Load Balancer (PLB)
output "plb_backend_pool_id" {
  value = azurerm_lb_backend_address_pool.plb_backend_pool.id
}

# Output the frontend IP configuration name of the Gateway Load Balancer (GWLB)
output "gwlb_frontend_ip" {
  value = azurerm_lb.gwlb.frontend_ip_configuration[0].name
}

# Output the public IP of the CLM VM for SSH access
output "clm_public_ip" {
  value = azurerm_public_ip.clm_public_ip.ip_address
}
