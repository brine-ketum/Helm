terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">=1.0"
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone_a" {
  description = "First availability zone"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_b" {
  description = "Second availability zone"
  type        = string
  default     = "us-east-1b"
}

variable "key_pair_name" {
  description = "AWS Key Pair name"
  type        = string
  default     = "aws-vtap-key"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/aws-key.pub"
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/aws-key"
}

variable "vpb_installer_path" {
  description = "Path to VPB installer script"
  type        = string
  default     = "/Users/brinketu/Downloads/vpb-3.10.0-18-install-package.sh"
}

variable "allowed_cidr" {
  description = "CIDR block allowed for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

# Provider configuration
provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Key Pair
resource "aws_key_pair" "vtap_key" {
  key_name   = var.key_pair_name
  public_key = file(var.ssh_public_key_path)

  tags = {
    Name        = "VTAP Key Pair"
    Environment = "Production"
  }
}

# VPC (Virtual Private Cloud) - equivalent to Azure VNet
resource "aws_vpc" "vtap_vpc" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "VTAP-VPC"
    Environment = "Production"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "vtap_igw" {
  vpc_id = aws_vpc.vtap_vpc.id

  tags = {
    Name        = "VTAP-IGW"
    Environment = "Production"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat_eip_a" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.vtap_igw]

  tags = {
    Name = "NAT-EIP-AZ-A"
  }
}

resource "aws_eip" "nat_eip_b" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.vtap_igw]

  tags = {
    Name = "NAT-EIP-AZ-B"
  }
}

# Subnets
resource "aws_subnet" "source_subnet" {
  vpc_id            = aws_vpc.vtap_vpc.id
  cidr_block        = "172.16.3.0/24"
  availability_zone = var.availability_zone_a

  tags = {
    Name = "Source-Subnet"
    Type = "Private"
  }
}

resource "aws_subnet" "destination_subnet" {
  vpc_id            = aws_vpc.vtap_vpc.id
  cidr_block        = "172.16.4.0/24"
  availability_zone = var.availability_zone_a

  tags = {
    Name = "Destination-Subnet"
    Type = "Private"
  }
}

resource "aws_subnet" "consumer_subnet" {
  vpc_id                  = aws_vpc.vtap_vpc.id
  cidr_block              = "172.16.10.0/24"
  availability_zone       = var.availability_zone_a
  map_public_ip_on_launch = true

  tags = {
    Name = "Consumer-Backend-Net"
    Type = "Public"
  }
}

resource "aws_subnet" "vpb_mgmt_subnet" {
  vpc_id                  = aws_vpc.vtap_vpc.id
  cidr_block              = "172.16.20.0/24"
  availability_zone       = var.availability_zone_a
  map_public_ip_on_launch = true

  tags = {
    Name = "VPB-Management"
    Type = "Public"
  }
}

resource "aws_subnet" "vpb_ingress_subnet" {
  vpc_id            = aws_vpc.vtap_vpc.id
  cidr_block        = "172.16.21.0/24"
  availability_zone = var.availability_zone_a

  tags = {
    Name = "VPB-Ingress"
    Type = "Private"
  }
}

resource "aws_subnet" "vpb_egress_subnet" {
  vpc_id            = aws_vpc.vtap_vpc.id
  cidr_block        = "172.16.22.0/24"
  availability_zone = var.availability_zone_a

  tags = {
    Name = "VPB-Egress"
    Type = "Private"
  }
}

resource "aws_subnet" "tool_subnet" {
  vpc_id                  = aws_vpc.vtap_vpc.id
  cidr_block              = "172.16.23.0/24"
  availability_zone       = var.availability_zone_a
  map_public_ip_on_launch = true

  tags = {
    Name = "Tool-Subnet"
    Type = "Public"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "nat_gw_a" {
  allocation_id = aws_eip.nat_eip_a.id
  subnet_id     = aws_subnet.consumer_subnet.id
  depends_on    = [aws_internet_gateway.vtap_igw]

  tags = {
    Name = "NAT-Gateway-AZ-A"
  }
}

# Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vtap_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vtap_igw.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vtap_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_a.id
  }

  tags = {
    Name = "Private-Route-Table"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_rta_consumer" {
  subnet_id      = aws_subnet.consumer_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rta_vpb_mgmt" {
  subnet_id      = aws_subnet.vpb_mgmt_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rta_tool" {
  subnet_id      = aws_subnet.tool_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rta_source" {
  subnet_id      = aws_subnet.source_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rta_destination" {
  subnet_id      = aws_subnet.destination_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rta_vpb_ingress" {
  subnet_id      = aws_subnet.vpb_ingress_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rta_vpb_egress" {
  subnet_id      = aws_subnet.vpb_egress_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Groups (equivalent to Azure NSG)
resource "aws_security_group" "web_sg" {
  name        = "web-security-group"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.vtap_vpc.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
    description = "SSH access"
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # Internal VPC communication
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/16"]
    description = "Internal VPC communication"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "Web-Security-Group"
  }
}

resource "aws_security_group" "vpb_sg" {
  name        = "vpb-security-group"
  description = "Security group for VPB"
  vpc_id      = aws_vpc.vtap_vpc.id

  # Allow all inbound
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all inbound for VPB"
  }

  # VXLAN traffic
  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "VXLAN traffic"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "VPB-Security-Group"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.vtap_vpc.id

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # SSH NAT ports
  ingress {
    from_port   = 60001
    to_port     = 60002
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
    description = "SSH NAT ports"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "ALB-Security-Group"
  }
}

# Network Interfaces for multi-NIC instances
resource "aws_network_interface" "web_server1_source_eni" {
  subnet_id       = aws_subnet.source_subnet.id
  security_groups = [aws_security_group.web_sg.id]
  source_dest_check = false

  tags = {
    Name = "WebServer1-Source-ENI"
  }
}

resource "aws_network_interface" "web_server1_dest_eni" {
  subnet_id       = aws_subnet.destination_subnet.id
  security_groups = [aws_security_group.web_sg.id]
  source_dest_check = false

  tags = {
    Name = "WebServer1-Destination-ENI"
  }
}

resource "aws_network_interface" "vpb_ingress_eni" {
  subnet_id       = aws_subnet.vpb_ingress_subnet.id
  security_groups = [aws_security_group.vpb_sg.id]
  source_dest_check = false

  tags = {
    Name = "VPB-Ingress-ENI"
  }
}

resource "aws_network_interface" "vpb_egress_eni" {
  subnet_id       = aws_subnet.vpb_egress_subnet.id
  security_groups = [aws_security_group.vpb_sg.id]
  source_dest_check = false

  tags = {
    Name = "VPB-Egress-ENI"
  }
}

# EC2 Instances
# WebServer1 with dual network interfaces
resource "aws_instance" "web_server1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "c5n.xlarge"
  key_name      = aws_key_pair.vtap_key.key_name
  subnet_id     = aws_subnet.source_subnet.id

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  source_dest_check      = false

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    apt-get update
    apt-get upgrade -y
    
    # Create azureuser account
    useradd -m -s /bin/bash azureuser
    usermod -aG sudo azureuser
    echo "azureuser:Keysight123456" | chpasswd
    
    # Set up SSH keys for azureuser
    mkdir -p /home/azureuser/.ssh
    echo "${file(var.ssh_public_key_path)}" >> /home/azureuser/.ssh/authorized_keys
    chown -R azureuser:azureuser /home/azureuser/.ssh
    chmod 700 /home/azureuser/.ssh
    chmod 600 /home/azureuser/.ssh/authorized_keys
    
    # Enable IP forwarding
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    sysctl -p
    
    # Install nginx and dependencies
    apt-get install -y nginx curl wget net-tools htop awscli
    
    # Create custom web page
    cat > /var/www/html/index.html << 'HTML'
    <!DOCTYPE html>
    <html>
    <head>
        <title>AWS VTAP WebServer1</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            .container { max-width: 600px; margin: 0 auto; }
            .info { background: #f0f0f0; padding: 20px; border-radius: 5px; margin: 20px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Welcome to AWS VTAP WebServer1</h1>
            <p>This server is running on Amazon Web Services with dual network interfaces</p>
            
            <div class="info">
                <h3>Network Configuration:</h3>
                <p><strong>Source subnet:</strong> 172.16.3.0/24</p>
                <p><strong>Destination subnet:</strong> 172.16.4.0/24</p>
                <p><strong>Load Balancer:</strong> Application Load Balancer</p>
                <p><strong>SSH NAT:</strong> Ports 60001 and 60002</p>
            </div>
        </div>
    </body>
    </html>
HTML
    
    # Configure and start nginx
    systemctl enable nginx
    systemctl start nginx
    
    # Enhanced networking configuration for SR-IOV
    echo 'net.core.rmem_default = 262144' >> /etc/sysctl.conf
    echo 'net.core.rmem_max = 16777216' >> /etc/sysctl.conf
    echo 'net.core.wmem_default = 262144' >> /etc/sysctl.conf
    echo 'net.core.wmem_max = 16777216' >> /etc/sysctl.conf
    sysctl -p
    
    # Log completion
    echo "WebServer1 startup completed at $(date)" > /var/log/webserver-startup.log
  EOF
  )

  tags = {
    Name        = "WebServer1"
    Environment = "Production"
    FastPath    = "enabled"
  }
}

# Attach secondary ENI to WebServer1
resource "aws_network_interface_attachment" "web_server1_dest_attachment" {
  instance_id          = aws_instance.web_server1.id
  network_interface_id = aws_network_interface.web_server1_dest_eni.id
  device_index         = 1
}

# Suricata IDS Instance
resource "aws_instance" "suricata" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "c5n.xlarge"
  key_name      = aws_key_pair.vtap_key.key_name
  subnet_id     = aws_subnet.tool_subnet.id

  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  source_dest_check          = false

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    apt-get update
    apt-get upgrade -y
    
    # Create azureuser account
    useradd -m -s /bin/bash azureuser
    usermod -aG sudo azureuser
    echo "azureuser:Keysight123456" | chpasswd
    
    # Set up SSH keys for azureuser
    mkdir -p /home/azureuser/.ssh
    echo "${file(var.ssh_public_key_path)}" >> /home/azureuser/.ssh/authorized_keys
    chown -R azureuser:azureuser /home/azureuser/.ssh
    chmod 700 /home/azureuser/.ssh
    chmod 600 /home/azureuser/.ssh/authorized_keys
    
    # Enable IP forwarding
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    sysctl -p
    
    # Install Suricata and dependencies
    apt-get install -y software-properties-common
    add-apt-repository -y ppa:oisf/suricata-stable
    apt-get update
    apt-get install -y suricata curl wget net-tools htop tcpdump awscli
    
    # Basic Suricata setup
    systemctl enable suricata
    
    # Log completion
    echo "Suricata startup completed at $(date)" > /var/log/suricata-startup.log
  EOF
  )

  tags = {
    Name        = "Suricata"
    Environment = "Production"
    Role        = "IDS"
  }
}

# VPB Instance with three network interfaces
resource "aws_instance" "vpb_vm" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "c5n.2xlarge"
  key_name      = aws_key_pair.vtap_key.key_name
  subnet_id     = aws_subnet.vpb_mgmt_subnet.id

  vpc_security_group_ids      = [aws_security_group.vpb_sg.id]
  associate_public_ip_address = true
  source_dest_check          = false

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    apt-get update
    apt-get upgrade -y
    
    # Create vpb user account
    useradd -m -s /bin/bash vpb
    usermod -aG sudo vpb
    echo "vpb:Keysight!123456" | chpasswd
    
    # Set up SSH keys for vpb user
    mkdir -p /home/vpb/.ssh
    echo "${file(var.ssh_public_key_path)}" >> /home/vpb/.ssh/authorized_keys
    chown -R vpb:vpb /home/vpb/.ssh
    chmod 700 /home/vpb/.ssh
    chmod 600 /home/vpb/.ssh/authorized_keys
    
    # Enable IP forwarding
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    sysctl -p
    
    # Install dependencies
    apt-get install -y curl wget net-tools htop tcpdump awscli
    
    # Enhanced networking configuration
    echo 'net.core.rmem_default = 262144' >> /etc/sysctl.conf
    echo 'net.core.rmem_max = 16777216' >> /etc/sysctl.conf
    echo 'net.core.wmem_default = 262144' >> /etc/sysctl.conf
    echo 'net.core.wmem_max = 16777216' >> /etc/sysctl.conf
    sysctl -p
    
    # Log completion
    echo "VPB startup completed at $(date)" > /var/log/vpb-startup.log
  EOF
  )

  tags = {
    Name        = "vPB"
    Environment = "Production"
    Role        = "PacketBroker"
  }
}

# Attach additional ENIs to VPB
resource "aws_network_interface_attachment" "vpb_ingress_attachment" {
  instance_id          = aws_instance.vpb_vm.id
  network_interface_id = aws_network_interface.vpb_ingress_eni.id
  device_index         = 1
}

resource "aws_network_interface_attachment" "vpb_egress_attachment" {
  instance_id          = aws_instance.vpb_vm.id
  network_interface_id = aws_network_interface.vpb_egress_eni.id
  device_index         = 2
}

# Application Load Balancer
resource "aws_lb" "vtap_alb" {
  name               = "vtap-application-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets           = [aws_subnet.consumer_subnet.id, aws_subnet.tool_subnet.id]

  enable_deletion_protection = false

  tags = {
    Name        = "VTAP-ALB"
    Environment = "Production"
  }
}

# Network Load Balancer for SSH NAT
resource "aws_lb" "vtap_nlb" {
  name               = "vtap-network-lb"
  internal           = false
  load_balancer_type = "network"
  subnets           = [aws_subnet.consumer_subnet.id, aws_subnet.tool_subnet.id]

  enable_deletion_protection = false

  tags = {
    Name        = "VTAP-NLB"
    Environment = "Production"
  }
}

# Target Groups
resource "aws_lb_target_group" "web_tg" {
  name     = "web-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vtap_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "Web-Target-Group"
  }
}

resource "aws_lb_target_group" "ssh_source_tg" {
  name     = "ssh-source-target-group"
  port     = 22
  protocol = "TCP"
  vpc_id   = aws_vpc.vtap_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    port                = "traffic-port"
    protocol            = "TCP"
    timeout             = 6
    unhealthy_threshold = 2
  }

  tags = {
    Name = "SSH-Source-Target-Group"
  }
}

resource "aws_lb_target_group" "ssh_dest_tg" {
  name     = "ssh-dest-target-group"
  port     = 22
  protocol = "TCP"
  vpc_id   = aws_vpc.vtap_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    port                = "traffic-port"
    protocol            = "TCP"
    timeout             = 6
    unhealthy_threshold = 2
  }

  tags = {
    Name = "SSH-Dest-Target-Group"
  }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "web_tg_attachment" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "ssh_source_tg_attachment" {
  target_group_arn = aws_lb_target_group.ssh_source_tg.arn
  target_id        = aws_instance.web_server1.id
  port             = 22
}

resource "aws_lb_target_group_attachment" "ssh_dest_tg_attachment" {
  target_group_arn = aws_lb_target_group.ssh_dest_tg.arn
  target_id        = aws_instance.web_server1.id
  port             = 22
}

# Load Balancer Listeners
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.vtap_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

resource "aws_lb_listener" "ssh_source_listener" {
  load_balancer_arn = aws_lb.vtap_nlb.arn
  port              = "60001"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ssh_source_tg.arn
  }
}

resource "aws_lb_listener" "ssh_dest_listener" {
  load_balancer_arn = aws_lb.vtap_nlb.arn
  port              = "60002"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ssh_dest_tg.arn
  }
}

# VPB Installation using remote-exec
resource "null_resource" "vpb_install" {
  depends_on = [aws_instance.vpb_vm]

  triggers = {
    script_checksum = filesha256(var.vpb_installer_path)
    instance_id     = aws_instance.vpb_vm.id
  }

  # Upload VPB installer
  provisioner "file" {
    source      = var.vpb_installer_path
    destination = "/home/vpb/vpb-installer.sh"

    connection {
      type        = "ssh"
      user        = "vpb"
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.vpb_vm.public_ip
      timeout     = "10m"
    }
  }

  # Install VPB
  provisioner "remote-exec" {
    inline = [
      "ls -l /home/vpb",
      "sleep 15",
      "if [ ! -f /home/vpb/.vpb_installed ]; then",
      "  chmod +x /home/vpb/vpb-installer.sh",
      "  sudo bash /home/vpb/vpb-installer.sh",
      "  touch /home/vpb/.vpb_installed",
      "else",
      "  echo 'VPB already installed. Skipping...'",
      "fi"
    ]

    connection {
      type        = "ssh"
      user        = "vpb"
      private_key = file(var.ssh_private_key_path)
      host        = aws_instance.vpb_vm.public_ip
      timeout     = "45m"
    }
  }
}

# Outputs
output "vpb_public_ip" {
  description = "Public IP address of the VPB instance"
  value       = aws_instance.vpb_vm.public_ip
}

output "application_load_balancer_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.vtap_alb.dns_name
}

output "network_load_balancer_dns" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.vtap_nlb.dns_name
}

output "suricata_public_ip" {
  description = "Public IP address of the Suricata instance"
  value       = aws_instance.suricata.public_ip
}

output "webserver1_source_private_ip" {
  description = "Private IP of WebServer1 source interface"
  value       = aws_instance.web_server1.private_ip
}

output "webserver1_dest_private_ip" {
  description = "Private IP of WebServer1 destination interface"
  value       = aws_network_interface.web_server1_dest_eni.private_ip
}

output "vpb_mgmt_private_ip" {
  description = "Private IP of VPB management interface"
  value       = aws_instance.vpb_vm.private_ip
}

output "vpb_ingress_private_ip" {
  description = "Private IP of VPB ingress interface"
  value       = aws_network_interface.vpb_ingress_eni.private_ip
}

output "vpb_egress_private_ip" {
  description = "Private IP of VPB egress interface"
  value       = aws_network_interface.vpb_egress_eni.private_ip
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.vtap_vpc.id
}

output "ssh_instructions" {
  description = "SSH connection instructions"
  value = <<EOF
SSH to WebServer1 via NLB (port 60001): ssh azureuser@${aws_lb.vtap_nlb.dns_name} -p 60001 -i ${var.ssh_private_key_path}
SSH to WebServer1 via NLB (port 60002): ssh azureuser@${aws_lb.vtap_nlb.dns_name} -p 60002 -i ${var.ssh_private_key_path}
SSH to Suricata: ssh azureuser@${aws_instance.suricata.public_ip} -i ${var.ssh_private_key_path}
SSH to VPB: ssh vpb@${aws_instance.vpb_vm.public_ip} -i ${var.ssh_private_key_path}
Web Access via ALB: http://${aws_lb.vtap_alb.dns_name}
EOF
}

output "load_balancer_details" {
  description = "Load balancer configuration details"
  value = <<EOF
Application Load Balancer (HTTP): ${aws_lb.vtap_alb.dns_name}
Network Load Balancer (SSH NAT): ${aws_lb.vtap_nlb.dns_name}
  - Port 60001: WebServer1 Source Interface SSH
  - Port 60002: WebServer1 Destination Interface SSH
EOF
}