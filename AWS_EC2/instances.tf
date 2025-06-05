terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region  = "us-west-2"
  profile = "brine"
}

variable "ubuntu_vm_count" {
  type    = number
  default = 1
}

variable "rhel_vm_count" {
  type    = number
  default = 1
}

variable "windows_vm_count" {
  type    = number
  default = 1
}

variable "rhel_ami_id" {
  type    = string
  default = "ami-0776d7ceda464f850" # For us-west-2, RHEL 8.x
}

# Create VPC
resource "aws_vpc" "brinek_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "BrineK"
  }
}

# Create Private Subnets in two Availability Zones
resource "aws_subnet" "brinek_private_subnet_a" {
  vpc_id                  = aws_vpc.brinek_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = false # IMPORTANT: Set to false
  tags = {
    Name = "brinekPrivateSubnetA"
  }
}

resource "aws_subnet" "brinek_private_subnet_b" {
  vpc_id                  = aws_vpc.brinek_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = false # IMPORTANT: Set to false
  tags = {
    Name = "brinekPrivateSubnetB"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "brinek_igw" {
  vpc_id = aws_vpc.brinek_vpc.id
  tags = {
    Name = "BrineK_IGW"
  }
}

# NAT Gateway - Required for private subnets to access the internet
resource "aws_nat_gateway" "brinek_nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.brinek_private_subnet_a.id # Place in one of the private subnets
  tags = {
    Name = "BrineK_NAT_Gateway"
  }

  depends_on = [aws_internet_gateway.brinek_igw]
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_gateway_eip" {
  domain = "vpc"
  tags = {
    Name = "BrineK_NAT_EIP"
  }
}

# Route Table for Private Subnets
resource "aws_route_table" "brinek_private_rt" {
  vpc_id = aws_vpc.brinek_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.brinek_nat_gateway.id
  }
  tags = {
    Name = "brinekPrivateRT"
  }
}

resource "aws_route_table_association" "brinek_private_assoc_a" {
  subnet_id      = aws_subnet.brinek_private_subnet_a.id
  route_table_id = aws_route_table.brinek_private_rt.id
}

resource "aws_route_table_association" "brinek_private_assoc_b" {
  subnet_id      = aws_subnet.brinek_private_subnet_b.id
  route_table_id = aws_route_table.brinek_private_rt.id
}

# Security Group equivalent to NSG for private instances - REVISED
resource "aws_security_group" "brinek_private_sg" {
  name        = "BrineK_Private_SG"
  description = "Security group for BrineK Private Instances"
  vpc_id      = aws_vpc.brinek_vpc.id

  #No ingress rules - allow outbound only, restrict this further if possible
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allowing all outbound; Consider restricting more
  }

  tags = {
    Name = "BrineK_Private_SG"
  }
}

# IAM Role and Instance Profile for SSM
resource "aws_iam_role" "ssm_instance_role" {
  name = "SSMInstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_managed_policy" {
  role       = aws_iam_role.ssm_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "SSMInstanceProfile"
  role = aws_iam_role.ssm_instance_role.name
}

# Key Pair for SSH (still needed, but won't be used directly for SSH)
resource "aws_key_pair" "brinek_key" {
  key_name   = "brinek_key"
  public_key = file("/Users/brinketu/Downloads/eks-terraform-key.pub")
}

# Ubuntu EC2 Instances
resource "aws_instance" "ubuntu_vm" {
  count                      = var.ubuntu_vm_count
  ami                        = data.aws_ami.ubuntu.id
  instance_type              = "t3.large"
  subnet_id                  = aws_subnet.brinek_private_subnet_a.id # Use private subnet A
  key_name                   = aws_key_pair.brinek_key.key_name
  vpc_security_group_ids     = [aws_security_group.brinek_private_sg.id] # Using the private SG
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  associate_public_ip_address = false #Ensure no public IP

  user_data = <<-EOF
            #!/bin/bash
            sudo apt-get update -y
            sudo apt-get install -y amazon-ssm-agent
            systemctl enable amazon-ssm-agent
            systemctl start amazon-ssm-agent
          EOF

  tags = {
    Name = "UbuntuVM-${count.index}"
    Env  = "Development"
  }
}

# Redhat EC2 Instances
resource "aws_instance" "rhel_vm" {
  count                      = var.rhel_vm_count
  ami                        = var.rhel_ami_id
  instance_type              = "t3.large"
  subnet_id                  = aws_subnet.brinek_private_subnet_a.id # Use private subnet A
  key_name                   = aws_key_pair.brinek_key.key_name
  vpc_security_group_ids     = [aws_security_group.brinek_private_sg.id] # Using the private SG
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  associate_public_ip_address = false #Ensure no public IP

  root_block_device {
    volume_size = 20
  }

user_data = <<-EOF
  #!/bin/bash
  yum install -y amazon-ssm-agent
  systemctl enable amazon-ssm-agent
  systemctl start amazon-ssm-agent
EOF

  tags = {
    Name = "RHELVM-${count.index}"
    Env  = "Development"
  }
}

# Windows EC2 Instances
resource "aws_instance" "windows_vm" {
  count                      = var.windows_vm_count
  ami                        = data.aws_ami.windows.id
  instance_type              = "t3.large"
  subnet_id                  = aws_subnet.brinek_private_subnet_b.id # Use private subnet B
  key_name                   = aws_key_pair.brinek_key.key_name
  vpc_security_group_ids     = [aws_security_group.brinek_private_sg.id] # Using the private SG
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  associate_public_ip_address = false #Ensure no public IP

  user_data = <<-EOF
    <powershell>
    # (Optional) You can install or restart SSM Agent here if needed
    </powershell>
  EOF

  tags = {
    Name = "WindowsVM-${count.index}"
    Env  = "Development"
  }
}

# Data sources for AMIs used in instances
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["801119661308"] # Amazon Windows

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
}

# Outputs for access information
output "ubuntu_instance_ids" {
  value       = [for instance in aws_instance.ubuntu_vm : instance.id]
  description = "Instance IDs of Ubuntu VMs"
}

output "rhel_instance_ids" {
  value       = [for instance in aws_instance.rhel_vm : instance.id]
  description = "Instance IDs of RHEL VMs"
}

output "windows_instance_ids" {
  value       = [for instance in aws_instance.windows_vm : instance.id]
  description = "Instance IDs of Windows VMs"
}

output "ansible_inventory_ips_only" {
  description = "Ansible inventory using only private IPs, with group vars for Windows"

  value = join("\n", concat(
    ["[ubuntu_vms]"],
    [for nic in azurerm_network_interface.ubuntu_nic : nic.private_ip_address],

    ["", "[redhat_vms]"],
    [for nic in azurerm_network_interface.rhel_nic : nic.private_ip_address],

    ["", "[windows]"],
    [for nic in azurerm_network_interface.windows_nic : nic.private_ip_address],

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
