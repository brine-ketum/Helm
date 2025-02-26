provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  # subscription_id = "15aa2ef1-8214-4cab-9974-d05715c7e9e8" 
  subscription_id = "16e5b426-6372-4975-908a-e4cc44ee3cab" 
}


variable "admin_username" {
  description = "The admin username for the VMs"
  default = "brine"
  type        = string
}

variable "admin_password" {
  description = "The admin password for the VMs"
  default = "Bravedemo123."
}

# Resource Group
resource "azurerm_resource_group" "tool_vm_rg" {
  name     = "ToolVMResourceGroup"
  location = "East US 2"
}

# Virtual Network
resource "azurerm_virtual_network" "tool_vm_vnet" {
  name                = "ToolVMVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.tool_vm_rg.location
  resource_group_name = azurerm_resource_group.tool_vm_rg.name
}

# Subnet with explicit dependency on Virtual Network
resource "azurerm_subnet" "tool_vm_public_subnet" {
  name                 = "ToolVMPublicSubnet"
  resource_group_name  = azurerm_resource_group.tool_vm_rg.name
  virtual_network_name = azurerm_virtual_network.tool_vm_vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [
    azurerm_virtual_network.tool_vm_vnet
  ]
}


# Create multiple Public IPs
resource "azurerm_public_ip" "tool_vm_public_ip" {
  count               = 2
  name                = "ToolVMPublicIP-${count.index}"
  location            = azurerm_resource_group.tool_vm_rg.location
  resource_group_name = azurerm_resource_group.tool_vm_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create multiple Network Interfaces
resource "azurerm_network_interface" "tool_vm_nic" {
  count               = 2
  name                = "ToolVMNic-${count.index}"
  location            = azurerm_resource_group.tool_vm_rg.location
  resource_group_name = azurerm_resource_group.tool_vm_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.tool_vm_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tool_vm_public_ip[count.index].id
  }
}
# Network Security Group
resource "azurerm_network_security_group" "tool_vm_nsg" {
  name                = "ToolVMNSG"
  location            = azurerm_resource_group.tool_vm_rg.location
  resource_group_name = azurerm_resource_group.tool_vm_rg.name

  security_rule {
    name                       = "AllowAllInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# NSG Association with explicit dependency on Virtual Network
resource "azurerm_subnet_network_security_group_association" "tool_vm_nsg_assoc" {
  subnet_id                 = azurerm_subnet.tool_vm_public_subnet.id
  network_security_group_id = azurerm_network_security_group.tool_vm_nsg.id

  depends_on = [
    azurerm_virtual_network.tool_vm_vnet
  ]
}


# Create two Ubuntu VMs dynamically
resource "azurerm_linux_virtual_machine" "tool_vm" {
  count               = 2
  name                = "Ubuntu-VM-${count.index}"
  resource_group_name = azurerm_resource_group.tool_vm_rg.name
  location            = azurerm_resource_group.tool_vm_rg.location
  size                = "Standard_DS1_v2"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.tool_vm_nic[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    disk_size_gb         = 127
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt-get install -y nginx
  EOF
  )

  disable_password_authentication = false

  tags = {
    Name = "ToolVM-${count.index}"
    Env  = "Demo"
  }
}



# # Public IP for Red Hat VM
# resource "azurerm_public_ip" "redhat_vm_public_ip" {
#   name                = "RedHatVMPublicIP"
#   location            = azurerm_resource_group.tool_vm_rg.location
#   resource_group_name = azurerm_resource_group.tool_vm_rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# # Network Interface for Red Hat VM
# resource "azurerm_network_interface" "redhat_vm_nic" {
#   name                = "RedHatVMNic"
#   location            = azurerm_resource_group.tool_vm_rg.location
#   resource_group_name = azurerm_resource_group.tool_vm_rg.name

#   ip_configuration {
#     name                          = "ipconfig1"
#     subnet_id                     = azurerm_subnet.tool_vm_public_subnet.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.redhat_vm_public_ip.id
#   }
# }

# # Red Hat Virtual Machine
# resource "azurerm_linux_virtual_machine" "redhat_vm" {
#   name                = "RedHatVM"
#   resource_group_name = azurerm_resource_group.tool_vm_rg.name
#   location            = azurerm_resource_group.tool_vm_rg.location
#   size                = "Standard_DS1_v2"
#   admin_username      = var.admin_username
#   admin_password      = var.admin_password
#   network_interface_ids = [
#     azurerm_network_interface.redhat_vm_nic.id,
#   ]

#   os_disk {
#     caching              = "ReadWrite"
#     disk_size_gb         = 127
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "RedHat"
#     offer     = "RHEL"
#     sku       = "8_4"
#     version   = "latest"
#   }

#   custom_data = base64encode(<<-EOF
#     #!/bin/bash
#     sudo yum update -y
#     sudo yum install -y httpd
#     sudo systemctl start httpd
#     sudo systemctl enable httpd
#   EOF
#   )

#   disable_password_authentication = false

#   tags = {
#     Name = "RedHatVM"
#     Env  = "Demo"
#   }
# }


# # Public IP for CentOS VM
# resource "azurerm_public_ip" "centos_vm_public_ip" {
#   name                = "CentOSVMPublicIP"
#   location            = azurerm_resource_group.tool_vm_rg.location
#   resource_group_name = azurerm_resource_group.tool_vm_rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# # Network Interface for CentOS VM
# resource "azurerm_network_interface" "centos_vm_nic" {
#   name                = "CentOSVMNic"
#   location            = azurerm_resource_group.tool_vm_rg.location
#   resource_group_name = azurerm_resource_group.tool_vm_rg.name

#   ip_configuration {
#     name                          = "ipconfig1"
#     subnet_id                     = azurerm_subnet.tool_vm_public_subnet.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.centos_vm_public_ip.id
#   }
# }

# # CentOS Virtual Machine
# resource "azurerm_linux_virtual_machine" "centos_vm" {
#   name                = "CentOSVM"
#   resource_group_name = azurerm_resource_group.tool_vm_rg.name
#   location            = azurerm_resource_group.tool_vm_rg.location
#   size                = "Standard_DS1_v2"
#   admin_username      = var.admin_username
#   admin_password      = var.admin_password
#   network_interface_ids = [
#     azurerm_network_interface.centos_vm_nic.id,
#   ]

#   os_disk {
#     caching              = "ReadWrite"
#     disk_size_gb         = 127
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "OpenLogic"
#     offer     = "CentOS"
#     sku       = "7_9"
#     version   = "latest"
#   }

#   custom_data = base64encode(<<-EOF
#     #!/bin/bash
#     sudo yum update -y
#     sudo yum install -y nginx
#     sudo systemctl start nginx
#     sudo systemctl enable nginx
#   EOF
#   )

#   disable_password_authentication = false

#   tags = {
#     Name = "CentOSVM"
#     Env  = "Demo"
#   }
# }

# # Public IP for Windows VM
# resource "azurerm_public_ip" "windows_vm_public_ip" {
#   name                = "WindowsVMPublicIP"
#   location            = azurerm_resource_group.tool_vm_rg.location
#   resource_group_name = azurerm_resource_group.tool_vm_rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# # Network Interface for Windows VM
# resource "azurerm_network_interface" "windows_vm_nic" {
#   name                = "WindowsVMNic"
#   location            = azurerm_resource_group.tool_vm_rg.location
#   resource_group_name = azurerm_resource_group.tool_vm_rg.name

#   ip_configuration {
#     name                          = "ipconfig1"
#     subnet_id                     = azurerm_subnet.tool_vm_public_subnet.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.windows_vm_public_ip.id
#   }
# }

# # Windows Virtual Machine
# resource "azurerm_windows_virtual_machine" "windows_vm" {
#   name                = "WindowsVM"
#   resource_group_name = azurerm_resource_group.tool_vm_rg.name
#   location            = azurerm_resource_group.tool_vm_rg.location
#   size                = "Standard_DS1_v2"
#   admin_username      = var.admin_username
#   admin_password      = var.admin_password
#   network_interface_ids = [
#     azurerm_network_interface.windows_vm_nic.id,
#   ]

#   os_disk {
#     caching              = "ReadWrite"
#     disk_size_gb         = 127
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "MicrosoftWindowsServer"
#     offer     = "WindowsServer"
#     sku       = "2019-Datacenter"
#     version   = "latest"
#   }

#   custom_data = base64encode(<<-EOF
#     <powershell>
#     Install-WindowsFeature -Name Web-Server
#     </powershell>
#   EOF
#   )

#   tags = {
#     Name = "WindowsVM"
#     Env  = "Demo"
#   }
# }

# # Output Public IP for Windows VM
# output "windows_vm_public_ip" {
#   value = azurerm_public_ip.windows_vm_public_ip.ip_address
# }


# # Output Public IP for CentOS VM
# output "centos_vm_public_ip" {
#   value = azurerm_public_ip.centos_vm_public_ip.ip_address
# }


# # Output Public IP for Red Hat VM
# output "redhat_vm_public_ip" {
#   value = azurerm_public_ip.redhat_vm_public_ip.ip_address
# }


# Output Public IPs of the two Ubuntu VMs
output "tool_vm_public_ips" {
  value = azurerm_public_ip.tool_vm_public_ip[*].ip_address
}