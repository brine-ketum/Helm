# Configure the Azure provider
provider "azurerm" {
  features {}
  subscription_id = "15aa2ef1-8214-4cab-9974-d05715c7e9e8"
}

# Create a resource group for the AVS deployment
resource "azurerm_resource_group" "avs_rg" {
  name     = "avs-RG"
  location = "East US"  # Specify your desired location
}

# Create a Public IP for the Ubuntu VM
resource "azurerm_public_ip" "ubuntu_vm_public_ip" {
  name                = "ubuntuVMPublicIP"
  resource_group_name = azurerm_resource_group.avs_rg.name
  location            = azurerm_resource_group.avs_rg.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

# Create a Public IP for the Windows VM
resource "azurerm_public_ip" "windows_vm_public_ip" {
  name                = "windowsVMPublicIP"
  resource_group_name = azurerm_resource_group.avs_rg.name
  location            = azurerm_resource_group.avs_rg.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

# Create a network interface for the Ubuntu VM
resource "azurerm_network_interface" "ubuntu_vm_nic" {
  name                = "ubuntuVMNIC"
  location            = azurerm_resource_group.avs_rg.location
  resource_group_name = azurerm_resource_group.avs_rg.name

  ip_configuration {
    name                          = "ipConfig"
    subnet_id                    = "azurerm_subnet.avs_subnet.id"  # Replace with your subnet ID
    private_ip_address_allocation = "Dynamic"

    public_ip_address_id = azurerm_public_ip.ubuntu_vm_public_ip.id
  }
}

# Create a network interface for the Windows VM
resource "azurerm_network_interface" "windows_vm_nic" {
  name                = "windowsVMNIC"
  location            = azurerm_resource_group.avs_rg.location
  resource_group_name = azurerm_resource_group.avs_rg.name

  ip_configuration {
    name                          = "ipConfig"
    subnet_id                    = "azurerm_subnet.avs_subnet.id"  # Replace with your subnet ID
    private_ip_address_allocation = "Dynamic"

    public_ip_address_id = azurerm_public_ip.windows_vm_public_ip.id
  }
}

# Deploy the Ubuntu Virtual Machine
resource "azurerm_linux_virtual_machine" "ubuntu_vm" {
  name                = "ubuntu-vm"
  resource_group_name = azurerm_resource_group.avs_rg.name
  location            = azurerm_resource_group.avs_rg.location
  size                = "Standard_DS1_v2"  # Choose the desired size
  network_interface_ids = [azurerm_network_interface.ubuntu_vm_nic.id]

  admin_username = "ubuntuadmin"
  admin_password = "P@ssword123!"  # Use a secure password

  os_disk {
    caching                = "ReadWrite"
    storage_account_type   = "Premium_LRS"  # Required argument
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  provision_vm_agent = true  # No change
}

# Deploy the Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "windows_vm" {
  name                = "windows-vm"
  resource_group_name = azurerm_resource_group.avs_rg.name
  location            = azurerm_resource_group.avs_rg.location
  size                = "Standard_DS1_v2"  # Choose the desired size
  network_interface_ids = [azurerm_network_interface.windows_vm_nic.id]

  admin_username = "azureuser"
  admin_password = "P@ssword123!"  # Use a secure password

  os_disk {
    caching                = "ReadWrite"
    storage_account_type   = "Premium_LRS"  # Required argument
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  provision_vm_agent        = true
  allow_extension_operations = true # No change
}

# Output the public IPs of the VMs
output "ubuntu_vm_public_ip" {
  value = azurerm_public_ip.ubuntu_vm_public_ip.ip_address  # Outputs the public IP of the Ubuntu VM
}

output "windows_vm_public_ip" {
  value = azurerm_public_ip.windows_vm_public_ip.ip_address  # Outputs the public IP of the Windows VM
}