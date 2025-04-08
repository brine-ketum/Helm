# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }

# # We strongly recommend using the required_providers block to set the
# # Azure Provider source and version being used
# terraform {
#   required_providers {
#     azurerm = {
#       source  = "hashicorp/azurerm"
#       version = "=3.0.0"
#     }
#   }
# }

# # Configure the Microsoft Azure Provider
# provider "azurerm" {
#   features {}
# }

# # Global Variables
# variable "prefix" {
#   default="demo"
# }

# # variable "ssl_private_cert_path" {
# #   type    = string
# #   default = "/Users/brinketu/CloudlensFIle/tasks/ssh-keys/jenkins_rsa"
# # }

# # variable "ssl_public_cert_path" {
# #   type    = string
# #   default = "/Users/brinketu/CloudlensFIle/tasks/ssh-keys/jenkins_rsa.pub"
# # }

# #VPB Variable

# variable "vpb_installer_path" {
#   type    = string
#   default = "/Users/brinketu/Downloads/vpb-3.8.0-28-install-package.sh"
# }

# variable "username" {
#   type    = string
#   default = "brine"
# }

# variable "admin_password" {
#   type    = string
# }

# # GWLB Variables
# variable "gwlb_name" {
#   type        = string
#   description = "Name of the gateway load balancer"
#   default     = "demo-gwlb"
# }

# variable "gwlb_frontend_ip_name" {
#   type        = string
#   description = "Name of the frontend IP configuration for GWLB"
#   default     = "gwlb-frontend-ip"
# }

# variable "gwlb_probe_name" {
#   type        = string
#   description = "Name of the health probe for GWLB"
#   default     = "gwlb-health-probe"
# }

# variable "gwlb_probe_protocol" {
#   type        = string
#   description = "Protocol for GWLB health probe"
#   default     = "Http"
# }

# variable "gwlb_probe_port" {
#   type        = number
#   description = "Port for GWLB health probe"
#   default     = 80
# }

# variable "gwlb_probe_interval" {
#   type        = number
#   description = "Interval for GWLB health probe"
#   default     = 15
# }

# variable "gwlb_probe_count" {
#   type        = number
#   description = "Number of probes for GWLB health check"
#   default     = 2
# }

# variable "gwlb_lb_rule_name" {
#   type        = string
#   description = "Name of the GWLB rule"
#   default     = "gwlb-rule"
# }

# variable "gwlb_rule_protocol" {
#   type        = string
#   description = "Protocol for GWLB rule"
#   default     = "All"
# }

# variable "gwlb_rule_frontend_port" {
#   type        = number
#   description = "Frontend port for GWLB rule"
#   default     = 0
# }

# variable "gwlb_rule_backend_port" {
#   type        = number
#   description = "Backend port for GWLB rule"
#   default     = 0
# }

# # PLB Variables
# variable "plb_name" {
#   type        = string
#   description = "Name of the platform load balancer"
#   default     = "demo-plb"
# }

# variable "plb_probe_request_path" {
#   type        = string
#   description = "Request path for PLB health probe"
#   default     = "/"
# }

# variable "plb_frontend_ip_name" {
#   type        = string
#   description = "Name of the frontend IP configuration for PLB"
#   default     = "plb-frontend-ip"
# }

# variable "plb_public_ip_name" {
#   type        = string
#   description = "Name of the public IP for PLB"
#   default     = "plb-public-ip"
# }

# variable "plb_probe_name" {
#   type        = string
#   description = "Name of the health probe for PLB"
#   default     = "plb-health-probe"
# }

# variable "plb_probe_protocol" {
#   type        = string
#   description = "Protocol for PLB health probe"
#   default     = "Http"
# }

# variable "plb_probe_port" {
#   type        = number
#   description = "Port for PLB health probe"
#   default     = 80
# }

# variable "plb_probe_interval" {
#   type        = number
#   description = "Interval for PLB health probe"
#   default     = 15
# }

# variable "plb_probe_count" {
#   type        = number
#   description = "Number of probes for PLB health check"
#   default     = 2
# }

# variable "plb_backend_pool_name" {
#   type        = string
#   description = "Name of the backend pool for PLB"
#   default     = "plb-backend-pool"
# }

# variable "plb_lb_rule_name" {
#   type        = string
#   description = "Name of the PLB rule"
#   default     = "plb-rule"
# }

# variable "plb_rule_protocol" {
#   type        = string
#   description = "Protocol for PLB rule"
#   default     = "Tcp"
# }

# variable "plb_rule_frontend_port" {
#   type        = number
#   description = "Frontend port for PLB rule"
#   default     = 80
# }

# variable "plb_rule_backend_port" {
#   type        = number
#   description = "Backend port for PLB rule"
#   default     = 80
# }

# # Resource Group
# resource "azurerm_resource_group" "rg" {
#   location = "eastus"
#   name     = "${var.prefix}-vpb-rg"
# }


# # Create virtual network
# resource "azurerm_virtual_network" "auto_vpb_vnet" {
#   name                = "${var.prefix}-vpb-vnet"
#   address_space       = ["10.0.0.0/16"]
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
# }

# # Create subnet
# resource "azurerm_subnet" "auto_vpb_subnet_main" {
#   name                 = "${var.prefix}-vpb-subnet-main"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.auto_vpb_vnet.name
#   address_prefixes     = ["10.0.1.0/24"]
# }

# # Create subnet for eth1 interfaces.
# resource "azurerm_subnet" "auto_vpb_subnet_eth1" {
#   name                 = "${var.prefix}-vpb-subnet-eth1"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.auto_vpb_vnet.name
#   address_prefixes     = ["10.0.2.0/24"]
# }

# # Create subnet for eth2 interfaces.
# resource "azurerm_subnet" "auto_vpb_subnet_eth2" {
#   name                 = "${var.prefix}-vpb-subnet-eth2"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.auto_vpb_vnet.name
#   address_prefixes     = ["10.0.3.0/24"]
# }

# # Create subnet for nginx VM
# resource "azurerm_subnet" "nginx_subnet" {
#   name                 = "${var.prefix}-nginx-subnet"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.auto_vpb_vnet.name
#   address_prefixes     = ["10.0.4.0/24"]
# }


# resource "azurerm_network_security_group" "auto_vpb_nsg" {
#   name                = "${var.prefix}-vpb-nsg"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name


# security_rule {
#     name                       = "Allow-All-Inbound"
#     priority                   = 100
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "80"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   security_rule {
#     name                       = "Allow-All-Outbound"
#     priority                   = 200
#     direction                  = "Outbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "80"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   security_rule {
#     name                       = "SSH"
#     priority                   = 300
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "22"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
  
#   security_rule {
#     name                       = "SSH-CLI"
#     priority                   = 301
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "2222"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   security_rule {
#     name                       = "SSH-REST"
#     priority                   = 302
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "8443"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   security_rule {
#     name                       = "SSH-HTTP"
#     priority                   = 303
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "443"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   security_rule {
#     name                       = "LIC-REST"
#     priority                   = 304
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "7443"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
# }


# ##########################
# #       VPB
# ##########################
# # Public IP for vPB
# resource "azurerm_public_ip" "auto_vpb_public_ip" {
#   name                = "${var.prefix}-vpb-public-ip"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# # Main interface for vPB
# resource "azurerm_network_interface" "auto_vpb_nic_main" {
#   name                = "${var.prefix}-vpb-nic-main"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   enable_accelerated_networking = true

#   ip_configuration {
#     name                          = "${var.prefix}-vpb-nic-main-config"
#     subnet_id                     = azurerm_subnet.auto_vpb_subnet_main.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.auto_vpb_public_ip.id
#   }

#    enable_ip_forwarding = true
# }

# # eth1 interface for vPB
# resource "azurerm_network_interface" "auto_vpb_nic_eth1" {
#   name                = "${var.prefix}-vpb-nic-eth1"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   enable_accelerated_networking = true

#   ip_configuration {
#     name                          = "${var.prefix}-vpb-nic-eth1-config"
#     subnet_id                     = azurerm_subnet.auto_vpb_subnet_eth1.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# # eth2 interface for vPB
# resource "azurerm_network_interface" "auto_vpb_nic_eth2" {
#   name                = "${var.prefix}-vpb-nic-eth2"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   enable_accelerated_networking = true

#   ip_configuration {
#     name                          = "${var.prefix}-vpb-nic-eth2-config"
#     subnet_id                     = azurerm_subnet.auto_vpb_subnet_eth2.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# # Network interface for nginx VM
# resource "azurerm_network_interface" "nginx_nic" {
#   name                = "${var.prefix}-nginx-nic"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   ip_configuration {
#     name                          = "${var.prefix}-nginx-nic-config"
#     subnet_id                     = azurerm_subnet.nginx_subnet.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.nginx_public_ip.id
#   }

# }

# # Connect the security group to the network interface
# resource "azurerm_network_interface_security_group_association" "auto_vpb_nsg_bind_main" {
#   network_interface_id      = azurerm_network_interface.auto_vpb_nic_main.id
#   network_security_group_id = azurerm_network_security_group.auto_vpb_nsg.id
# }

# # Associate the VPB security group with nginx VM's network interface
# resource "azurerm_network_interface_security_group_association" "nginx_nsg_association" {
#   network_interface_id      = azurerm_network_interface.nginx_nic.id
#   network_security_group_id = azurerm_network_security_group.auto_vpb_nsg.id
# }

# resource "azurerm_network_interface_security_group_association" "auto_vpb_nsg_bind_eth1" {
#   network_interface_id      = azurerm_network_interface.auto_vpb_nic_eth1.id
#   network_security_group_id = azurerm_network_security_group.auto_vpb_nsg.id
# }
# resource "azurerm_network_interface_security_group_association" "auto_vpb_nsg_bind_eth2" {
#   network_interface_id      = azurerm_network_interface.auto_vpb_nic_eth2.id
#   network_security_group_id = azurerm_network_security_group.auto_vpb_nsg.id
# }


# # VM for vPB
# resource "azurerm_linux_virtual_machine" "auto_vpb_vm" {
#   name                  = "${var.prefix}-vpb-vm"
#   admin_username        = var.username
#   admin_password        = var.admin_password  
#   location              = azurerm_resource_group.rg.location
#   resource_group_name   = azurerm_resource_group.rg.name
#   network_interface_ids = [
#     azurerm_network_interface.auto_vpb_nic_main.id,
#     azurerm_network_interface.auto_vpb_nic_eth1.id,
#     azurerm_network_interface.auto_vpb_nic_eth2.id,
#     ]
#   size                  = "Standard_D8s_v4"

#   os_disk {
#     name                 = "auto_vpb_disk"
#     caching              = "ReadWrite"
#     storage_account_type = "Premium_LRS"
#   }

#   # admin_ssh_key {
#   #   username   = var.username
#   #   public_key = file("${var.ssl_public_cert_path}")
#   # }
#  # Enable password-based authentication and disable SSH key requirement
#   disable_password_authentication = false
  
#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-jammy"
#     sku       = "22_04-lts-gen2"
#     version   = "latest"
#   }
# }

# ##########################
# #       Traffic Box
# ##########################
# # Public IP for vPB
# resource "azurerm_public_ip" "auto_tb_public_ip" {
#   name                = "${var.prefix}-tb-public-ip"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# # Main interface for vPB
# resource "azurerm_network_interface" "auto_tb_nic_main" {
#   name                = "${var.prefix}-tb-nic-main"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   enable_accelerated_networking = true

#   ip_configuration {
#     name                          = "${var.prefix}-tb-nic-main-config"
#     subnet_id                     = azurerm_subnet.auto_vpb_subnet_main.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.auto_tb_public_ip.id
#   }
# }

# # eth1 interface for vPB
# resource "azurerm_network_interface" "auto_tb_nic_eth1" {
#   name                = "${var.prefix}-tb-nic-eth1"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   enable_accelerated_networking = true

#   ip_configuration {
#     name                          = "${var.prefix}-tb-nic-eth1-config"
#     subnet_id                     = azurerm_subnet.auto_vpb_subnet_eth1.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# # eth2 interface for vPB
# resource "azurerm_network_interface" "auto_tb_nic_eth2" {
#   name                = "${var.prefix}-tb-nic-eth2"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   enable_accelerated_networking = true

#   ip_configuration {
#     name                          = "${var.prefix}-tb-nic-eth2-config"
#     subnet_id                     = azurerm_subnet.auto_vpb_subnet_eth2.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# # Connect the security group to the network interface
# resource "azurerm_network_interface_security_group_association" "auto_tb_nsg_bind_main" {
#   network_interface_id      = azurerm_network_interface.auto_tb_nic_main.id
#   network_security_group_id = azurerm_network_security_group.auto_vpb_nsg.id
# }
# resource "azurerm_network_interface_security_group_association" "auto_tb_nsg_bind_eth1" {
#   network_interface_id      = azurerm_network_interface.auto_tb_nic_eth1.id
#   network_security_group_id = azurerm_network_security_group.auto_vpb_nsg.id
# }
# resource "azurerm_network_interface_security_group_association" "auto_tb_nsg_bind_eth2" {
#   network_interface_id      = azurerm_network_interface.auto_tb_nic_eth2.id
#   network_security_group_id = azurerm_network_security_group.auto_vpb_nsg.id
# }

# # VM for vPB
# resource "azurerm_linux_virtual_machine" "auto_tb_vm" {
#   name                  = "${var.prefix}-tb-vm"
#   admin_username        = var.username
#   admin_password        = var.admin_password
#   location              = azurerm_resource_group.rg.location
#   resource_group_name   = azurerm_resource_group.rg.name
#   network_interface_ids = [
#     azurerm_network_interface.auto_tb_nic_main.id,
#     azurerm_network_interface.auto_tb_nic_eth1.id,
#     # azurerm_network_interface.auto_tb_nic_eth2.id,
#     ]
#   size                  = "Standard_D8s_v4"

#   os_disk {
#     name                 = "auto_tb_disk"
#     caching              = "ReadWrite"
#     storage_account_type = "Premium_LRS"
#   }

# #   admin_ssh_key {
# #     username   = var.username
# #     public_key = file("${var.ssl_public_cert_path}")
# #   }

# #  Enable password-based authentication and disable SSH key requirement
#   disable_password_authentication = false

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-jammy"
#     sku       = "22_04-lts-gen2"
#     version   = "latest"
#   }

# }


# resource "null_resource" "vpb_installation" {
#   connection {
#     type        = "ssh"
#     user        = var.username
#     password    = var.admin_password
#     timeout     = "45m"
#     # private_key = file("${var.ssl_private_cert_path}")
#     host        = azurerm_linux_virtual_machine.auto_vpb_vm.public_ip_address
#   }

#   # Use file provisioner to copy the local installer to the VM
#   provisioner "file" {
#     source      = "${var.vpb_installer_path}"  # Local path
#     destination = "/home/${var.username}/vpb.sh"  # Destination on the VM
#   }

#   # Make the script executable and run it on the remote VM
#   provisioner "remote-exec" {
#     inline = [
#       "chmod u+x /home/${var.username}/vpb.sh",
#       "/home/${var.username}/vpb.sh"
#     ]
#   }

#   provisioner "local-exec" {
#   command = <<-EOT
#     mkdir -p /tmp/tasks-out/;
#     echo ${azurerm_linux_virtual_machine.auto_vpb_vm.public_ip_address} > /Users/brinketu/CloudlensFIle/tasks/tasks-out/vpb_ip.txt;
#     find /Users/brinketu/CloudlensFIle/tasks/tasks-out/ > /Users/brinketu/CloudlensFIle/tasks/tasks-out/fillist.txt
#   EOT
# }

# }

# # resource "null_resource" "vpb_nginx_installation" {
# #   depends_on = [null_resource.vpb_installation]

# #   connection {
# #     type        = "ssh"
# #     user        = var.username
# #     password    = var.admin_password
# #     timeout     = "10m"
# #     host        = azurerm_linux_virtual_machine.auto_vpb_vm.public_ip_address
# #   }

# #   provisioner "remote-exec" {
# #     inline = [
# #       "sudo apt-get update",
# #       "sudo apt-get install -y nginx",
# #       "sudo systemctl start nginx",
# #       "sudo systemctl enable nginx"
# #     ]
# #   }
# # }

# # resource "null_resource" "trafficbox_setup" {
# #   connection {
# #     type     = "ssh"
# #     user     = var.username
# #     password = var.admin_password
# #     timeout = "45m"
# #     # private_key = file("${var.ssl_private_cert_path}")
# #     host     = azurerm_linux_virtual_machine.auto_tb_vm.public_ip_address
# #   }

# #   provisioner "local-exec" {
# #     command = "curl http://10.38.209.168/content/vpb/script/docker-setup.sh -o \"${path.cwd}/docker-setup.sh\""
# #   }

# #   provisioner "local-exec" {
# #     command = "sleep 20"
# #   }

# #   provisioner "file" {
# #     source      = "${path.cwd}/docker-setup.sh"
# #     destination = "/home/${var.username}/docker-setup.sh"
# #   }

# #   provisioner "remote-exec" {
# #     inline = [
# #       "chmod u+x /home/${var.username}/docker-setup.sh",
# #       "/home/${var.username}/docker-setup.sh"
# #       ]
# #   }
# # }


# # Nginx VM

# resource "azurerm_linux_virtual_machine" "nginx_vm" {
#   name                  = "${var.prefix}-nginx-vm"
#   location              = azurerm_resource_group.rg.location
#   resource_group_name   = azurerm_resource_group.rg.name
#   network_interface_ids = [azurerm_network_interface.nginx_nic.id]
#   size                  = "Standard_DS2_v2"
#   os_disk {
#     name                 = "${var.prefix}-nginx-osdisk"
#     caching              = "ReadWrite"
#     storage_account_type = "Premium_LRS"
#   }

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-jammy"
#     sku       = "22_04-lts-gen2"
#     version   = "latest"
#   }

#   admin_username                  = var.username
#   admin_password                  = var.admin_password
#   disable_password_authentication = false
#   depends_on = [azurerm_linux_virtual_machine.auto_vpb_vm]
# }

# # Install Nginx on the VM
# resource "null_resource" "nginx_installation" {
#   depends_on = [azurerm_linux_virtual_machine.nginx_vm]
#   connection {
#     type     = "ssh"
#     user     = var.username
#     password = var.admin_password
#     host     = azurerm_public_ip.nginx_public_ip.ip_address
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo apt-get update",
#       "sudo apt-get install -y nginx",
#       "sudo systemctl start nginx",
#       "sudo systemctl enable nginx"
#     ]
#   }
# }

# # Public IP for nginx VM
# resource "azurerm_public_ip" "nginx_public_ip" {
#   name                = "${var.prefix}-nginx-public-ip"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }



# # Add ICMP rule to the existing security group
# resource "azurerm_network_security_rule" "allow_icmp" {
#   name                        = "AllowICMP"
#   priority                    = 1001
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Icmp"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = azurerm_resource_group.rg.name
#   network_security_group_name = azurerm_network_security_group.auto_vpb_nsg.name

# }
# #GWLB 

# # Gateway Load Balancer (GWLB)
# resource "azurerm_lb" "gwlb" {
#   name                = var.gwlb_name
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   sku                 = "Gateway"

#   frontend_ip_configuration {
#     name                          = var.gwlb_frontend_ip_name
#     subnet_id                     = azurerm_subnet.auto_vpb_subnet_main.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# # Health Probe for GWLB
# resource "azurerm_lb_probe" "gwlb_health_probe" {
#   loadbalancer_id     = azurerm_lb.gwlb.id
#   name                = var.gwlb_probe_name
#   protocol            = var.gwlb_probe_protocol
#   port                = var.gwlb_probe_port
#   interval_in_seconds = var.gwlb_probe_interval
#   number_of_probes    = var.gwlb_probe_count
#   request_path        = "/"  
# }

# # Load Balancer Rule for GWLB traffic forwarding
# resource "azurerm_lb_rule" "gwlb_rule" {
#   loadbalancer_id                = azurerm_lb.gwlb.id
#   name                           = var.gwlb_lb_rule_name
#   protocol                       = var.gwlb_rule_protocol
#   frontend_port                  = var.gwlb_rule_frontend_port
#   backend_port                   = var.gwlb_rule_backend_port
#   frontend_ip_configuration_name = azurerm_lb.gwlb.frontend_ip_configuration[0].name
#   probe_id                       = azurerm_lb_probe.gwlb_health_probe.id
#   backend_address_pool_ids       = [azurerm_lb_backend_address_pool.gwlb_backend_pool.id]
# }

# # Backend Address Pool for GWLB
# resource "azurerm_lb_backend_address_pool" "gwlb_backend_pool" {
#   loadbalancer_id = azurerm_lb.gwlb.id
#   name            = "gwlb-backend-pool"
#   tunnel_interface {
#     identifier = 800
#     type       = "Internal"
#     protocol   = "VXLAN"
#     port       = 10800
#   }
#   tunnel_interface {
#     identifier = 801
#     type       = "External"
#     protocol   = "VXLAN"
#     port       = 10801
#   }
# }

# # Associate VPB VM eth1 interface with GWLB backend pool
# resource "azurerm_network_interface_backend_address_pool_association" "vpb_gwlb_association" {
#   network_interface_id    = azurerm_network_interface.auto_vpb_nic_eth1.id
#   ip_configuration_name   = azurerm_network_interface.auto_vpb_nic_eth1.ip_configuration[0].name
#   backend_address_pool_id = azurerm_lb_backend_address_pool.gwlb_backend_pool.id

#   # Ensure this association is deleted before the VM and NIC
#   depends_on = [
#     azurerm_linux_virtual_machine.auto_vpb_vm
#   ]
# }



# # Platform Load Balancer (PLB)
# resource "azurerm_lb" "plb" {
#   name                = var.plb_name
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   sku                 = "Standard"

#   frontend_ip_configuration {
#     name                 = var.plb_frontend_ip_name
#     public_ip_address_id = azurerm_public_ip.plb_public_ip.id
#   }
#    # Ensure PLB creation waits for GWLB
#   depends_on = [azurerm_lb.gwlb]
# }

# # Public IP for PLB (for internet-facing communication)
# resource "azurerm_public_ip" "plb_public_ip" {
#   name                = var.plb_public_ip_name
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"

#   depends_on = [azurerm_lb.gwlb]
# }


# # Health Probe for PLB
# resource "azurerm_lb_probe" "plb_health_probe" {
#   loadbalancer_id     = azurerm_lb.plb.id
#   name                = var.plb_probe_name
#   protocol            = var.plb_probe_protocol
#   port                = var.plb_probe_port
#   interval_in_seconds = var.plb_probe_interval
#   number_of_probes    = var.plb_probe_count
#   request_path        = var.plb_probe_request_path

#  depends_on = [azurerm_lb.gwlb]
# }

# # Backend Pool for PLB
# resource "azurerm_lb_backend_address_pool" "plb_backend_pool" {
#   name            = var.plb_backend_pool_name
#   loadbalancer_id = azurerm_lb.plb.id

#   depends_on = [azurerm_lb.gwlb]
# }

# # Load Balancer Rule for traffic forwarding (PLB to GWLB)
# resource "azurerm_lb_rule" "plb_rule" {
#   loadbalancer_id                = azurerm_lb.plb.id
#   name                           = var.plb_lb_rule_name
#   protocol                       = var.plb_rule_protocol
#   frontend_port                  = var.plb_rule_frontend_port
#   backend_port                   = var.plb_rule_backend_port
#   frontend_ip_configuration_name = azurerm_lb.plb.frontend_ip_configuration[0].name
#   probe_id                       = azurerm_lb_probe.plb_health_probe.id
#   backend_address_pool_ids       = [azurerm_lb_backend_address_pool.plb_backend_pool.id]

#   depends_on = [azurerm_lb.gwlb]
# }

# # Associate GWLB with PLB backend pool
# resource "azurerm_lb_backend_address_pool_address" "gwlb_plb_association" {
#   name                    = "gwlb-plb-association"
#   backend_address_pool_id = azurerm_lb_backend_address_pool.plb_backend_pool.id
#   virtual_network_id      = azurerm_virtual_network.auto_vpb_vnet.id
#   ip_address              = azurerm_lb.gwlb.private_ip_address

#   depends_on = [
#     azurerm_network_interface.auto_vpb_nic_eth1,
#     azurerm_lb.gwlb,
#     azurerm_lb.plb
#   ]
# }

# # Associate the PLB subnet with the existing Network Security Group (NSG)
# resource "azurerm_subnet_network_security_group_association" "plb_nsg_association" {
#   subnet_id                 = azurerm_subnet.auto_vpb_subnet_main.id
#   network_security_group_id = azurerm_network_security_group.auto_vpb_nsg.id
# }

# output "demo_vpb_public_ip" {
#   value = azurerm_linux_virtual_machine.auto_vpb_vm.public_ip_address
# }

# output "demo_plb_public_ip" {
#   value = azurerm_public_ip.plb_public_ip.ip_address
# }

# # Output the public IP of the nginx VM
# output "nginx_public_ip" {
#   value = azurerm_public_ip.nginx_public_ip.ip_address
# }
# # output "demo_tb_public_ip" {
# #   value = azurerm_linux_virtual_machine.auto_tb_vm.public_ip_address
# # }