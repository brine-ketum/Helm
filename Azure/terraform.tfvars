resource_group_name = "cloudlens-rg"
vm_name             = "cloudlens-manager-vm"
admin_username      = "azureuser"
admin_password      = "P@ssw0rd123!" # Ensure to update this for production use
image_reference = {
  publisher = "Canonical"
  offer     = "UbuntuServer"
  sku       = "20.04-LTS" # Set to "18.04-LTS" for Ubuntu 18
  version   = "latest"
}
installer_url      = "https://example.com/path/to/CloudLens-Installer-<version>.sh" # Update to actual URL
installer_version  = "<version>" # Specify desired version