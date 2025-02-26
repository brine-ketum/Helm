# # Web Workload Ubuntu VM NIC
# resource "azurerm_network_interface" "web_workload_nic" {
#   name                = var.web_workload_nic_name
#   location            = var.location
#   resource_group_name = azurerm_resource_group.plb_gwlb_rg.name

#   ip_configuration {
#     name                          = var.web_workload_ipconfig_name
#     subnet_id                     = azurerm_subnet.traffic_subnet.id
#     private_ip_address_allocation = "Dynamic"
#   }

#   lifecycle {
#     prevent_destroy = false #destroys vm before destroying assocaited resources
#   }

#   depends_on = [
#     azurerm_subnet.traffic_subnet,
#     azurerm_lb.plb,
#     azurerm_lb_backend_address_pool.plb_backend_pool
#   ]
# }

# # Wkload Public IP Address
# resource "azurerm_public_ip" "wkload_public_ip" {
#   name                = "wkloadip"
#   location            = var.location
#   resource_group_name = azurerm_resource_group.plb_gwlb_rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# # Wkload Network Security Group (Allow SSH and All Traffic)
# resource "azurerm_network_security_group" "wkload_nsg" {
#   name                = var.wkload_nsg
#   location            = var.location
#   resource_group_name = azurerm_resource_group.plb_gwlb_rg.name

#   security_rule {
#     name                       = "AllowAllInbound"
#     priority                   = 300
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "*"
#     source_port_range          = "*"
#     destination_port_range     = "*"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   security_rule {
#     name                       = "AllowAllOutbound"
#     priority                   = 400
#     direction                  = "Outbound"
#     access                     = "Allow"
#     protocol                   = "*"
#     source_port_range          = "*"
#     destination_port_range     = "*"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

# }
# # Backend Pool Association for Web Workload NIC
# resource "azurerm_network_interface_backend_address_pool_association" "web_workload_backend_pool_assoc" {
#   network_interface_id            = azurerm_network_interface.web_workload_nic.id
#   ip_configuration_name           = azurerm_network_interface.web_workload_nic.ip_configuration[0].name
#   backend_address_pool_id         = azurerm_lb_backend_address_pool.plb_backend_pool.id
# }

# # Web Workload Ubuntu VM
# resource "azurerm_linux_virtual_machine" "web_workload_vm" {
#   name                  = var.web_workload_vm_name
#   resource_group_name   = azurerm_resource_group.plb_gwlb_rg.name
#   location              = var.location
#   size                  = var.web_workload_vm_size
#   admin_username        = var.admin_username
#   admin_password        = var.admin_password
#   disable_password_authentication = false
#   network_interface_ids = [
#     azurerm_network_interface.web_workload_nic.id
#   ]

#   os_disk {
#     caching              = var.os_disk_caching
#     storage_account_type = var.os_disk_storage_account_type
#     disk_size_gb         = var.web_workload_os_disk_size_gb
#   }

#   source_image_reference {
#     publisher = var.image_publisher
#     offer     = var.image_offer
#     sku       = var.image_sku
#     version   = var.image_version
#   }

#   tags = {
#     Name = var.web_workload_vm_name
#     Env  = var.env
#   }

#   depends_on = [
#     azurerm_network_interface.web_workload_nic,
#     azurerm_network_interface_backend_address_pool_association.web_workload_backend_pool_assoc
#   ]
# }
