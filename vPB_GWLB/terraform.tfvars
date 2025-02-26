# Subscription and Resource Group Info
subscription_id          = "15aa2ef1-8214-4cab-9974-d05715c7e9e8"
resource_group_name      = "DemoResourceGroup"
location                 = "East US"

# VNET and Subnet Info
vnet_name                = "DemoVNet"
vnet_address_space       = ["10.0.0.0/16"]
mgmt_subnet_name         = "DemoMgmtSubnet"
mgmt_subnet_prefix       = ["10.0.1.0/24"]
traffic_subnet_name      = "DemoTrafficSubnet"
traffic_subnet_prefix    = ["10.0.2.0/24"]
tools_subnet_name        = "DemoToolsSubnet"
tools_subnet_prefix      = ["10.0.3.0/24"]

# Platform Load Balancer (PLB) Info
plb_name                 = "PLB"
plb_frontend_ip_name     = "PLBFrontendIP"
plb_public_ip_name       = "PLBPublicIP"
plb_probe_name           = "PLBHealthProbe"
plb_probe_protocol       = "Tcp"
plb_probe_port           = 80
plb_probe_interval       = 5
plb_probe_count          = 2
plb_backend_pool_name    = "PLBBackendPool"
plb_lb_rule_name         = "PLBRoutingRule"
plb_rule_protocol        = "Tcp"
plb_rule_frontend_port   = 80
plb_rule_backend_port    = 80
nsg_name                 = "demo_sg"




# Gateway Load Balancer (GWLB) Info
gwlb_name                = "GWLB"
gwlb_frontend_ip_name    = "GWLBFrontendIP"
gwlb_probe_name          = "GWLBHealthProbe"
gwlb_probe_protocol      = "Tcp"
gwlb_probe_port          = 22
gwlb_probe_interval      = 5
gwlb_probe_count         = 2
gwlb_lb_rule_name        = "GWLBRoutingRule"
gwlb_rule_protocol       = "All"
gwlb_rule_frontend_port  = 0
gwlb_rule_backend_port   = 0

# vPacketStack Info
vpb_vm_name                   = "VPB"
vpb_nsg                       = "vpbsg"
vm_size                       = "Standard_D8s_v3"
vpb_mgmt_nic_name             = "VPacketStackMgmtNIC"
vpb_traffic_nic_name          = "VPacketStackTrafficNIC"
vpb_tools_nic_name            = "VPacketStackToolsNIC"
vpacketstack_public_ip_name   = "PacketStackPublicIP"
vpacketstack_ipconfig_mgmt    = "VPacketStackIPConfigMgmt"
vpacketstack_ipconfig_tools   = "VPacketStackIPConfigTools"
vpacketstack_ipconfig_traffic = "VPacketStackIPConfigTraffic"
# vpb_installer_path = "/Users/brinketu/CloudlensFIle/vpb-3.7.0-34-install-package.sh" # Path to the local vPB installer script

# OS Disk Info
os_disk_size_gb          = 200
os_disk_caching          = "ReadWrite"
os_disk_storage_account_type = "Standard_LRS"

# OS Image Info
image_publisher          = "Canonical"
image_offer              = "0001-com-ubuntu-server-focal"
image_sku                = "20_04-lts"
image_version            = "latest"

# CLM VM Information
clm_nic_name            = "CLMNIC"
clm_ipconfig_name       = "CLMIPConfig"
clm_vm_name             = "clmserver"
clm_nsg                 = "clm_sg"
clm_vm_size             = "Standard_E4s_v3"  # 8 vCPUs, 16 GB RAM
clm_os_disk_size_gb     = 100  # At least 100 GB for the root partition
installer_path = "/Users/brinketu/CloudlensFIle/CloudLens-Installer-6.9.1-47.sh" # Path to the local CloudLens installer script

# Environment Info
env                      = "demo"
