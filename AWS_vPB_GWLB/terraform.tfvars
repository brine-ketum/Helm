# AWS General Information
aws_region              = "us-east-1"
profile             = "brine"

# VPC and Subnet Information
vpc_cidr_block          = "10.0.0.0/16"
vpc_name                = "DemoVPC"

mgmt_subnet_name        = "ManagementSubnet"
mgmt_subnet_cidr        = "10.0.1.0/24"

traffic_subnet_name     = "TrafficSubnet"
traffic_subnet_cidr     = "10.0.2.0/24"

tools_subnet_name       = "ToolsSubnet"
tools_subnet_cidr       = "10.0.3.0/24"

availability_zone       = "us-east-1a"

# Security Group Information
instance_sg_name        = "InstanceSecurityGroup"

# Gateway Load Balancer (GWLB) Information
gwlb_name               = "GWLB"
gwlb_probe_name         = "GWLBHealthCheck"
gwlb_probe_port         = 80
gwlb_probe_protocol     = "HTTP"
gwlb_probe_interval     = 10
gwlb_probe_count        = 3
gwlb_lb_rule_name       = "GWLBListenerRule"
gwlb_rule_protocol      = "TCP"
gwlb_rule_frontend_port = 80

# EC2 Information for vPacketStack
vm_instance_type        = "t3.medium"
vm_key_name             = "vPacketStackKeyPair"
vm_image_id = "ami-083654bd07b5da81d"  # Ubuntu 20.04  

# OS Disk Information
os_disk_size_gb         = 30  # Size of OS disk

# Environment Information
env                     = "demo"
