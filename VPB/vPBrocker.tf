terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

variable "vpb_installer_path" {
  type    = string
  default = "/Users/brinketu/Downloads/vpb-3.9.0-42-install-package.sh"
}

variable "prefix" {
  default="demo"
}

# variable "ssl_private_cert_path" {
#   type    = string
#   default = "/Users/brinketu/CloudlensFIle/tasks/ssh-keys/jenkins_rsa"
# }

# variable "ssl_public_cert_path" {
#   type    = string
#   default = "/Users/brinketu/CloudlensFIle/tasks/ssh-keys/jenkins_rsa.pub"
# }

variable "username" {
  type    = string
  default = "brine"
}

variable "admin_password" {
  type    = string
}

# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  location = "eastus"
  name     = "${var.prefix}-vpb-rg"
}

# Create virtual network
resource "azurerm_virtual_network" "auto_vpb_vnet" {
  name                = "${var.prefix}-vpb-vnet"
  address_space       = ["192.168.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "auto_vpb_subnet_main" {
  name                 = "${var.prefix}-vpb-subnet-main"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.auto_vpb_vnet.name
  address_prefixes     = ["192.168.0.0/24"]
}

# Create subnet for eth1 interfaces.
resource "azurerm_subnet" "auto_vpb_subnet_eth1" {
  name                 = "${var.prefix}-vpb-subnet-eth1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.auto_vpb_vnet.name
  address_prefixes     = ["192.168.1.0/24"]
}

# Create subnet for eth2 interfaces.
resource "azurerm_subnet" "auto_vpb_subnet_eth2" {
  name                 = "${var.prefix}-vpb-subnet-eth2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.auto_vpb_vnet.name
  address_prefixes     = ["192.168.2.0/24"]
}

resource "azurerm_network_security_group" "auto_vpb_nsg" {
  name                = "${var.prefix}-vpb-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "SSH-CLI"
    priority                   = 301
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2222"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH-REST"
    priority                   = 302
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH-HTTP"
    priority                   = 303
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "LIC-REST"
    priority                   = 304
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "7443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


##########################
#       VPB
##########################
# Public IP for vPB
resource "azurerm_public_ip" "auto_vpb_public_ip" {
  name                = "${var.prefix}-vpb-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Main interface for vPB
resource "azurerm_network_interface" "auto_vpb_nic_main" {
  name                = "${var.prefix}-vpb-nic-main"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "${var.prefix}-vpb-nic-main-config"
    subnet_id                     = azurerm_subnet.auto_vpb_subnet_main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.auto_vpb_public_ip.id
  }
}

# eth1 interface for vPB
resource "azurerm_network_interface" "auto_vpb_nic_eth1" {
  name                = "${var.prefix}-vpb-nic-eth1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "${var.prefix}-vpb-nic-eth1-config"
    subnet_id                     = azurerm_subnet.auto_vpb_subnet_eth1.id
    private_ip_address_allocation = "Dynamic"
  }
}

# eth2 interface for vPB
resource "azurerm_network_interface" "auto_vpb_nic_eth2" {
  name                = "${var.prefix}-vpb-nic-eth2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "${var.prefix}-vpb-nic-eth2-config"
    subnet_id                     = azurerm_subnet.auto_vpb_subnet_eth2.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "auto_vpb_nsg_bind_main" {
  network_interface_id      = azurerm_network_interface.auto_vpb_nic_main.id
  network_security_group_id = azurerm_network_security_group.auto_vpb_nsg.id
}

/*
resource "azurerm_network_interface_security_group_association" "auto_vpb_nsg_bind_eth1" {
  network_interface_id      = azurerm_network_interface.auto_vpb_nic_eth1.id
  network_security_group_id = azurerm_network_security_group.auto_vpb_nsg.id
}
resource "azurerm_network_interface_security_group_association" "auto_vpb_nsg_bind_eth2" {
  network_interface_id      = azurerm_network_interface.auto_vpb_nic_eth2.id
  network_security_group_id = azurerm_network_security_group.auto_vpb_nsg.id
}
*/

# VM for vPB
resource "azurerm_linux_virtual_machine" "auto_vpb_vm" {
  name                  = "${var.prefix}-vpb-vm"
  admin_username        = var.username
  admin_password        = var.admin_password  
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [
    azurerm_network_interface.auto_vpb_nic_main.id,
    azurerm_network_interface.auto_vpb_nic_eth1.id,
    azurerm_network_interface.auto_vpb_nic_eth2.id,
    ]
  size                  = "Standard_D8s_v4"

  os_disk {
    name                 = "auto_vpb_disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  # admin_ssh_key {
  #   username   = var.username
  #   public_key = file("${var.ssl_public_cert_path}")
  # }
 # Enable password-based authentication and disable SSH key requirement
  disable_password_authentication = false
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

##########################
#       Traffic Box
##########################
# Public IP for vPB
resource "azurerm_public_ip" "auto_tb_public_ip" {
  name                = "${var.prefix}-tb-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Main interface for vPB
resource "azurerm_network_interface" "auto_tb_nic_main" {
  name                = "${var.prefix}-tb-nic-main"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "${var.prefix}-tb-nic-main-config"
    subnet_id                     = azurerm_subnet.auto_vpb_subnet_main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.auto_tb_public_ip.id
  }
}

# eth1 interface for vPB
resource "azurerm_network_interface" "auto_tb_nic_eth1" {
  name                = "${var.prefix}-tb-nic-eth1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "${var.prefix}-tb-nic-eth1-config"
    subnet_id                     = azurerm_subnet.auto_vpb_subnet_eth1.id
    private_ip_address_allocation = "Dynamic"
  }
}

# eth2 interface for vPB
resource "azurerm_network_interface" "auto_tb_nic_eth2" {
  name                = "${var.prefix}-tb-nic-eth2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "${var.prefix}-tb-nic-eth2-config"
    subnet_id                     = azurerm_subnet.auto_vpb_subnet_eth2.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "auto_tb_nsg_bind_main" {
  network_interface_id      = azurerm_network_interface.auto_tb_nic_main.id
  network_security_group_id = azurerm_network_security_group.auto_vpb_nsg.id
}
resource "azurerm_network_interface_security_group_association" "auto_tb_nsg_bind_eth1" {
  network_interface_id      = azurerm_network_interface.auto_tb_nic_eth1.id
  network_security_group_id = azurerm_network_security_group.auto_vpb_nsg.id
}
resource "azurerm_network_interface_security_group_association" "auto_tb_nsg_bind_eth2" {
  network_interface_id      = azurerm_network_interface.auto_tb_nic_eth2.id
  network_security_group_id = azurerm_network_security_group.auto_vpb_nsg.id
}

# VM for vPB
resource "azurerm_linux_virtual_machine" "auto_tb_vm" {
  name                  = "${var.prefix}-tb-vm"
  admin_username        = var.username
  admin_password        = var.admin_password
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [
    azurerm_network_interface.auto_tb_nic_main.id,
    azurerm_network_interface.auto_tb_nic_eth1.id,
    # azurerm_network_interface.auto_tb_nic_eth2.id,
    ]
  size                  = "Standard_D8s_v4"

  os_disk {
    name                 = "auto_tb_disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  # admin_ssh_key {
  #   username   = var.username
  #   public_key = file("${var.ssl_public_cert_path}")
  # }

 # Enable password-based authentication and disable SSH key requirement
  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

}

resource "null_resource" "vpb_installation" {
  connection {
    type        = "ssh"
    user        = var.username
    password    = var.admin_password
    timeout     = "45m"
    # private_key = file("${var.ssl_private_cert_path}")
    host        = azurerm_linux_virtual_machine.auto_vpb_vm.public_ip_address
  }

  # Use file provisioner to copy the local installer to the VM
  provisioner "file" {
    source      = "${var.vpb_installer_path}"  # Local path
    destination = "/home/${var.username}/vpb.sh"  # Destination on the VM
  }

  # Make the script executable and run it on the remote VM
  provisioner "remote-exec" {
    inline = [
      "chmod u+x /home/${var.username}/vpb.sh",
      "/home/${var.username}/vpb.sh"
    ]
  }

  provisioner "local-exec" {
  command = <<-EOT
    mkdir -p /tmp/tasks-out/;
    echo ${azurerm_linux_virtual_machine.auto_vpb_vm.public_ip_address} > /Users/brinketu/CloudlensFIle/tasks/tasks-out/vpb_ip.txt;
    echo ${azurerm_linux_virtual_machine.auto_tb_vm.public_ip_address} > /Users/brinketu/CloudlensFIle/tasks/tasks-out/trafficbox_ip.txt;
    find /Users/brinketu/CloudlensFIle/tasks/tasks-out/ > /Users/brinketu/CloudlensFIle/tasks/tasks-out/fillist.txt
  EOT
}

}


resource "null_resource" "trafficbox_setup" {
  connection {
    type     = "ssh"
    user     = var.username
    password = var.admin_password
    timeout = "45m"
    # private_key = file("${var.ssl_private_cert_path}")
    host     = azurerm_linux_virtual_machine.auto_tb_vm.public_ip_address
  }

  provisioner "local-exec" {
    command = "curl http://10.38.209.168/content/vpb/script/docker-setup.sh -o \"${path.cwd}/docker-setup.sh\""
  }

  provisioner "local-exec" {
    command = "sleep 20"
  }

  provisioner "file" {
    source      = "${path.cwd}/docker-setup.sh"
    destination = "/home/${var.username}/docker-setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod u+x /home/${var.username}/docker-setup.sh",
      "/home/${var.username}/docker-setup.sh"
      ]
  }
}

output "demo_vpb_public_ip" {
  value = azurerm_linux_virtual_machine.auto_vpb_vm.public_ip_address
}

output "demo_tb_public_ip" {
  value = azurerm_linux_virtual_machine.auto_tb_vm.public_ip_address
}