subscription_id = "15aa2ef1-8214-4cab-9974-d05715c7e9e8"
resource_group_name = "DemoResourceGroup"
location            = "East US"
vnet_name           = "DemoVNet"
address_space       = ["10.0.0.0/16"]
subnet_name         = "DemoPublicSubnet"
subnet_address_prefix = ["10.0.1.0/24"]

public_ips = {
  Ubuntu  = "UbuntuPublicIP"
  Windows = "WindowsPublicIP"
#   RHEL    = "RHELPublicIP"
  clm     = "CLMPublicIP"
  VPB     = "VPBPublicIP"
}

nsg_name = "DemoCloudLensNSG"

vm_settings = {
  Ubuntu = {
    os_type         = "Linux"
    vm_size         = "Standard_B1s"
    os_disk_size_gb = 127
    publisher       = "Canonical"
    offer           = "0001-com-ubuntu-server-focal"
    sku             = "20_04-lts"
  }

#   RHEL = {
#     os_type         = "Linux"
#     vm_size         = "Standard_B1s"
#     os_disk_size_gb = 127
#     publisher       = "RedHat"
#     offer           = "RHEL"
#     sku             = "8-LVM"
#   }

  clm = {
    os_type         = "Linux"
    vm_size         = "Standard_D4s_v3"
    os_disk_size_gb = 200
    publisher       = "Canonical"
    offer           = "0001-com-ubuntu-server-focal"
    sku             = "20_04-lts"
  }

  Windows = {
    os_type         = "Windows"
    vm_size         = "Standard_B1s"
    os_disk_size_gb = 127
    publisher       = "MicrosoftWindowsServer"
    offer           = "WindowsServer"
    sku             = "2019-Datacenter"
  }

  VPB = {
    os_type         = "Linux"
    vm_size         = "Standard_D4s_v3"   
    os_disk_size_gb = 200
    publisher       = "Canonical"
    offer           = "0001-com-ubuntu-server-focal"
    sku             = "20_04-lts"
  }
}
