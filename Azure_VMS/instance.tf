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

# Resource Group
resource "azurerm_resource_group" "brinek_rg" {
  name     = "BrineK"
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
    source_address_prefix      = "40.143.44.44/32"  # Change to your actual IP or CIDR
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
  source_address_prefix      = "40.143.44.44/32"  # or restrict to control server IP
  destination_address_prefix = "*"
}
}

resource "azurerm_subnet_network_security_group_association" "brinek_nsg_assoc" {
  subnet_id                 = azurerm_subnet.brinek_public_subnet.id
  network_security_group_id = azurerm_network_security_group.brinek_nsg.id
}

# Loop for 5 VMs
resource "azurerm_public_ip" "ubuntu_pip" {
  count               = 1
  name                = "UbuntuPublicIP-${count.index}"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "ubuntu_nic" {
  count               = 1
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
  count                 = 1
  name                  = "UbuntuVM-${count.index}"
  resource_group_name   = azurerm_resource_group.brinek_rg.name
  location              = azurerm_resource_group.brinek_rg.location
  size                  = "Standard_B1s"
  admin_username        = "brine"
  disable_password_authentication = true

  network_interface_ids = [azurerm_network_interface.ubuntu_nic[count.index].id]

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

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y nginx
  EOF
  )

  tags = {
    Name = "UbuntuVM-${count.index}"
    Env  = "Development"
  }
}

output "public_ips" {
  value = [for pip in azurerm_public_ip.ubuntu_pip : pip.ip_address]
}

output "ssh_instructions" {
  value = [for i in range(1) : "ssh -i eks-terraform-key.pem brine@${azurerm_public_ip.ubuntu_pip[i].ip_address}"]
}

output "ansible_inventory" {
  value = join("\n", concat(
    ["[azure_vms]"],
    [for i, pip in azurerm_public_ip.ubuntu_pip :
      "server${i + 1} ansible_host=${pip.ip_address}"
    ]
  ))
}

#push to an inv with =======> terraform output ansible_inventory > inventory.ini
#Public IP for RHEL VM
resource "azurerm_public_ip" "rhel_public_ip" {
  name                = "RHELPublicIP"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

#Network Interface for RHEL VM
resource "azurerm_network_interface" "rhel_nic" {
  name                = "RHELNIC"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.brinek_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.rhel_public_ip.id
  }
}


# RHEL Linux VM
resource "azurerm_linux_virtual_machine" "rhel_vm" {
  name                = "RHELVM"
  resource_group_name = azurerm_resource_group.brinek_rg.name
  location            = azurerm_resource_group.brinek_rg.location
  size                = "Standard_D4s_v3"
  admin_username      = "brine"
  admin_password      = "Bravedemo123."
  network_interface_ids = [
    azurerm_network_interface.rhel_nic.id,
  ]

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

custom_data = base64encode(<<-EOF
  #!/bin/bash
  sudo yum update -y
  sudo yum install httpd -y
  sudo systemctl enable httpd
  sudo systemctl start httpd
EOF
)
  disable_password_authentication = true

  admin_ssh_key {
  username   = "brine"
  public_key = file("/Users/brinketu/Downloads/eks-terraform-key.pub")
}

  tags = {
    Name = "RHELVM"
    Env  = "Development"
  }
}

#Centos
resource "azurerm_public_ip" "centos_public_ip" {
  name                = "CentOSPublicIP"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "centos_nic" {
  name                = "CentOSNIC"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.brinek_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.centos_public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "centos_vm" {
  name                = "CentOSVM"
  resource_group_name = azurerm_resource_group.brinek_rg.name
  location            = azurerm_resource_group.brinek_rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "brine"
  admin_password      = "Bravedemo123."  # Only if you're using password auth

  network_interface_ids = [
    azurerm_network_interface.centos_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    disk_size_gb         = 127
    storage_account_type = "Standard_LRS"
  }

admin_ssh_key {
  username   = "brine"
  public_key = file("/Users/brinketu/Downloads/eks-terraform-key.pub")
}

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_9"
    version   = "latest"
  }

disable_password_authentication = true

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y httpd
    sudo systemctl enable httpd
    sudo systemctl start httpd
  EOF
  )

  tags = {
    Name = "CentOSVM"
    Env  = "Development"
  }
}

# Windows VM
# Public IP for Windows VM
resource "azurerm_public_ip" "windows_public_ip" {
  name                = "WindowsPublicIP"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Interface for Windows VM
resource "azurerm_network_interface" "windows_nic" {
  name                = "WindowsNIC"
  location            = azurerm_resource_group.brinek_rg.location
  resource_group_name = azurerm_resource_group.brinek_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.brinek_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.windows_public_ip.id
  }
}

# Windows VM
resource "azurerm_windows_virtual_machine" "windows_vm" {
  name                = "WindowsVM"
  resource_group_name = azurerm_resource_group.brinek_rg.name
  location            = azurerm_resource_group.brinek_rg.location
  size                = "Standard_D4s_v3"
  admin_username      = "brineadmin"
  admin_password      = "Bravedemo123."  # Ensure this meets Azure password complexity requirements
  depends_on = [azurerm_network_interface.windows_nic]

  network_interface_ids = [
    azurerm_network_interface.windows_nic.id,
  ]

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

  provision_vm_agent        = true
  enable_automatic_updates  = true
  # Custom Data to enable RDP and WinRM
  # This script enables RDP, configures firewall rules, and starts the WinRM service


custom_data = base64encode(<<-EOF

<powershell>

  #Enable RDP and set to Private Network
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
    Name = "WindowsVM"
    Env  = "Development"
  }
}

# Uncomment the following block only after deploying the Windows VM


# This extension configures WinRM for Ansible
# resource "azurerm_virtual_machine_extension" "winrm_config" {
#   name                 = "winrm-config-extension"
#   virtual_machine_id   = azurerm_windows_virtual_machine.windows_vm.id
#   publisher            = "Microsoft.Compute"
#   type                 = "CustomScriptExtension"
#   type_handler_version = "1.10"  # latest stable version

#   # Use 'settings' for non-sensitive public config only, but fileUris is sensitive - use protected_settings
#   settings = <<SETTINGS
# {}
# SETTINGS

#   protected_settings = <<PROTECTED_SETTINGS
# {
#   "fileUris": [
#     "https://raw.githubusercontent.com/ansible/ansible/stable-2.9/examples/scripts/ConfigureRemotingForAnsible.ps1"
#   ],
#   "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File ConfigureRemotingForAnsible.ps1"
# }
# PROTECTED_SETTINGS

#   depends_on = [azurerm_windows_virtual_machine.windows_vm]
# }
# Output to get the RDP command
output "rdp_command_to_windows" {
  value = "mstsc /v:${azurerm_public_ip.windows_public_ip.ip_address}"
}


output "centos_public_ip" {
  value = azurerm_public_ip.centos_public_ip.ip_address
}
output "centos_ssh_command" {
  value = "ssh -i /path/to/your/private/key brine@${azurerm_public_ip.centos_public_ip.ip_address}"
}
output "ssh_command_to_rhel" {
  value = "ssh -i /path/to/your/private/key brine@${azurerm_public_ip.rhel_public_ip.ip_address}"
}


#Test RDP Access
# Once applied:

# Run: terraform output rdp_command_to_windows

# Paste into the Run dialog (Windows + R)

# Enter credentials: brineadmin / BraveDemoWin123!