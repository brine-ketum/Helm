terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "16e5b426-6372-4975-908a-e4cc44ee3cab"
}

# Variables for VM counts
variable "ubuntu_vm_count" {
  description = "Number of Ubuntu VMs to create"
  type        = number
  default     = 4
}

variable "rhel_vm_count" {
  description = "Number of RHEL VMs to create"
  type        = number
  default     = 3
}

variable "windows_vm_count" {
  description = "Number of Windows VMs to create"
  type        = number
  default     = 3
}

variable "windows_admin_password" {
  description = "Admin password for the Windows VM"
  type        = string
  default     = "Bravedemo123."
  sensitive   = true
}

# Resource Group
resource "azurerm_resource_group" "brinek_rg" {
  name     = "ketum"
  location = "EastUS2"
}

# Virtual Network
resource "azurerm_virtual_network" "brinek_vnet" {
  name                = "brinekVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name
}

# Subnet
resource "azurerm_subnet" "brinek_public_subnet" {
  name                 = "brinekPublicSubnet"
  resource_group_name  = azurerm_resource_group.brinek_rg.name
  virtual_network_name = azurerm_virtual_network.brinek_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# NSG
resource "azurerm_network_security_group" "brinek_nsg" {
  name                = "BrinekNSG"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name

  security_rule {
    name                       = "AllowSSHInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "40.143.44.44/32"
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

  security_rule {
    name                       = "AllowRDPInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "40.143.44.44/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowWinRMInbound"
    priority                   = 115
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["5985", "5986"]
    source_address_prefix      = "40.143.44.44/32"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "brinek_nsg_assoc" {
  subnet_id                 = azurerm_subnet.brinek_public_subnet.id
  network_security_group_id = azurerm_network_security_group.brinek_nsg.id
}

# Ubuntu VM
resource "azurerm_public_ip" "ubuntu_pip" {
  count               = var.ubuntu_vm_count
  name                = "UbuntuPublicIP-${count.index}"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name
  allocation_method   = "Static"
  sku                 = "Basic" 
}

resource "azurerm_network_interface" "ubuntu_nic" {
  count               = var.ubuntu_vm_count
  name                = "UbuntuNIC-${count.index}"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.brinek_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ubuntu_pip[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "ubuntu_vm" {
  count                         = var.ubuntu_vm_count
  name                          = "UbuntuVM-${count.index}"
  resource_group_name           = azurerm_resource_group.brinek_rg.name
  location                      = azurerm_resource_group.brinek_rg.location
  size                          = "Standard_D4s_v3" # 4 vCPUs, 16 GB RAM
  admin_username                = "brine"
  disable_password_authentication = true
  network_interface_ids         = [azurerm_network_interface.ubuntu_nic[count.index].id]

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

  admin_ssh_key {
    username   = "brine"
    public_key = file("/Users/brinketu/Downloads/eks-terraform-key.pub")
  }

  tags = {
    Name = "UbuntuVM-${count.index}"
    Env  = "prod"
    OS   = "Ubuntu"
  }
}

#Ntop Tool VM
resource "azurerm_public_ip" "ntop_tool_pip" {
  name                = "ntopToolPublicIP"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name
  allocation_method   = "Static"
  sku                 = "Basic" 
}

resource "azurerm_network_interface" "ntop_tool_nic" {
  name                = "ntopToolNIC"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.brinek_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ntop_tool_pip.id
  }
}

# resource "azurerm_linux_virtual_machine" "ntop_tool" {
#   name                            = "ntop-tool"
#   resource_group_name             = azurerm_resource_group.brinek_rg.name
#   location                        = azurerm_resource_group.brinek_rg.location
#   size                            = "Standard_D4s_v3" # 4 vCPUs, 16 GB RAM
#   admin_username                  = "brine"
#   disable_password_authentication = true
#   network_interface_ids           = [azurerm_network_interface.ntop_tool_nic.id]

#   os_disk {
#     caching              = "ReadWrite"
#     disk_size_gb         = 127
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-focal"
#     sku       = "20_04-lts"
#     version   = "latest"
#   }

#   admin_ssh_key {
#     username   = "brine"
#     public_key = file("/Users/brinketu/Downloads/eks-terraform-key.pub")
#   }

#   custom_data = base64encode(<<-EOF
#     #!/bin/bash
#     sudo apt update
#     sudo apt install -y software-properties-common wget gnupg tcpdump net-tools
#     wget https://packages.ntop.org/apt/ntop.key
#     sudo apt-key add ntop.key
#     echo "deb https://packages.ntop.org/apt/20.04/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/ntop.list
#     echo "deb https://packages.ntop.org/apt-stable/20.04/ $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/ntop.list
#     sudo apt update
#     sudo apt install -y ntopng
#     sudo systemctl enable ntopng
#     sudo systemctl start ntopng
#   EOF
#   )


#   tags = {
#     Name = "ntop-tool"
#     Role = "Monitoring"
#   }
# }

# RHEL VM
resource "azurerm_public_ip" "rhel_pip" {
  count               = var.rhel_vm_count
  name                = "RHELPublicIP-${count.index}"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "rhel_nic" {
  count               = var.rhel_vm_count
  name                = "RHELNIC-${count.index}"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.brinek_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.rhel_pip[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "rhel_vm" {
  count                         = var.rhel_vm_count
  name                          = "RHELVM-${count.index}"
  resource_group_name           = azurerm_resource_group.brinek_rg.name
  location                      = azurerm_resource_group.brinek_rg.location
  size                          = "Standard_D4s_v3" 
  admin_username                = "brine"
  disable_password_authentication = true
  network_interface_ids         = [azurerm_network_interface.rhel_nic[count.index].id]

  os_disk {
    caching              = "ReadWrite"
    disk_size_gb         = 127
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8-LVM"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "brine"
    public_key = file("/Users/brinketu/Downloads/eks-terraform-key.pub")
  }

  tags = {
    Name = "RHELVM-${count.index}"
    Env  = "prod"
    OS   = "RHEL"
  }
}

# Windows VM

resource "azurerm_public_ip" "windows_pip" {
  count               = var.windows_vm_count
  name                = "WindowsPublicIP-${count.index}"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "windows_nic" {
  count               = var.windows_vm_count
  name                = "WindowsNIC-${count.index}"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.brinek_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.windows_pip[count.index].id
  }
}
# Create a Windows VM with WinRM enabled for Ansible
resource "azurerm_windows_virtual_machine" "windows_vm" {
  count                       = var.windows_vm_count
  name                        = "WindowsVM-${count.index}"
  resource_group_name         = azurerm_resource_group.brinek_rg.name
  location                    = azurerm_resource_group.brinek_rg.location
  size                        = "Standard_D4s_v3"
  admin_username              = "brine"
  admin_password              = var.windows_admin_password
  network_interface_ids       = [azurerm_network_interface.windows_nic[count.index].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 127
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  provision_vm_agent       = true
  enable_automatic_updates = true

  custom_data = base64encode(<<-EOF
  <powershell>
    Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -Name "fDenyTSConnections" -Value 0
    Get-NetFirewallRule -DisplayGroup "Remote Desktop" | Enable-NetFirewallRule
    Set-Service -Name TermService -StartupType Automatic
    Start-Service TermService
    Set-ItemProperty -Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Terminal Server\\WinStations\\RDP-Tcp' -Name 'UserAuthentication' -Value 0
    Set-NetConnectionProfile -InterfaceAlias "Ethernet" -NetworkCategory Private
  </powershell>
  EOF
  )

  tags = {
    Name = "WindowsVM-${count.index}"
    Env  = "prod"
    OS   = "Windows"
  }

  depends_on = [azurerm_network_interface.windows_nic]
}

# Uncomment this block on after windows deployment, if you want to enable WinRM for Ansible on Windows VMs
resource "azurerm_virtual_machine_extension" "winrm_config" {
  count               = var.windows_vm_count
  name                = "winrm-config-extension-${count.index}"
  virtual_machine_id  = azurerm_windows_virtual_machine.windows_vm[count.index].id
  publisher           = "Microsoft.Compute"
  type                = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
{}
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
{
  "fileUris": [
    "https://raw.githubusercontent.com/ansible/ansible/stable-2.9/examples/scripts/ConfigureRemotingForAnsible.ps1"
  ],
  "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File ConfigureRemotingForAnsible.ps1"
}
PROTECTED_SETTINGS

  depends_on = [azurerm_windows_virtual_machine.windows_vm]
}

# Outputs
output "public_ips" {
  value = concat(
    [for pip in azurerm_public_ip.ubuntu_pip : pip.ip_address],
    [for pip in azurerm_public_ip.rhel_pip : pip.ip_address],
    [for pip in azurerm_public_ip.windows_pip : pip.ip_address]
  )
}

output "ssh_instructions_to_ubuntu" {
  value = [for i in range(var.ubuntu_vm_count) : "ssh -i /Users/brinketu/Downloads/eks-terraform-key.pem brine@${azurerm_public_ip.ubuntu_pip[i].ip_address}"]
}

output "ssh_command_to_rhel" {
  value = [for i in range(var.rhel_vm_count) : "ssh -i /Users/brinketu/Downloads/eks-terraform-key.pem brine@${azurerm_public_ip.rhel_pip[i].ip_address}"]
}

output "rdp_command_to_windows" {
  value = [for i in range(var.windows_vm_count) : "mstsc /v:${azurerm_public_ip.windows_pip[i].ip_address}"]
}

# output "ssh_to_ntop_tool" {
#   value       = "ssh -i /Users/brinketu/Downloads/eks-terraform-key.pem brine@${azurerm_public_ip.ntop_tool_pip.ip_address}"
# }

# output "private_ip_of_ntop_tool" {
#   description = "Private IP address of the ntop_tool VM"
#   value       = azurerm_network_interface.ntop_tool_nic.private_ip_address
# }


output "ansible_inventory" {
  value = join("\n", concat(
    ["[ubuntu_vms]"],
    [for pip in azurerm_public_ip.ubuntu_pip : pip.ip_address],

    ["", "[redhat_vms]"],
    [for pip in azurerm_public_ip.rhel_pip : pip.ip_address],

    ["", "[windows]"],
    [for pip in azurerm_public_ip.windows_pip : pip.ip_address],

    ["", "[windows:vars]"],
    [
      "ansible_user=brine",
      "ansible_password=Bravedemo123.",
      "ansible_connection=winrm",
      "ansible_winrm_transport=ntlm",
      "ansible_winrm_server_cert_validation=ignore"
    ]
  ))
}
