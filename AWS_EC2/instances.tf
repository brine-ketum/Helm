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
  default = 0
}

variable "rhel_vm_count" {
  type    = number
  default = 0
}

variable "windows_vm_count" {
  type    = number
  default = 1
}

variable "rhel_ami_id" {
  type    = string
  # default = "ami-0140c344ea05bbd7a" # For us-east-1, RHEL 8.x
  default = "ami-0776d7ceda464f850" # For us-west-2, RHEL 8.x
}

# Create VPC
resource "aws_vpc" "brinek_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "BrineK"
  }
}


resource "aws_security_group_rule" "winrm_https_inbound" {
  type              = "ingress"
  from_port         = 5986
  to_port           = 5986
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.brinek_sg.id
  description       = "Allow WinRM HTTPS"
}

# Create Public Subnets in two Availability Zones
resource "aws_subnet" "brinek_public_subnet_a" {
  vpc_id                  = aws_vpc.brinek_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a" # Changed to us-west-2a
  map_public_ip_on_launch = true
  tags = {
    Name = "brinekPublicSubnetA"
  }
}

resource "aws_subnet" "brinek_public_subnet_b" {
  vpc_id                  = aws_vpc.brinek_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b" # Changed to us-west-2b
  map_public_ip_on_launch = true
  tags = {
    Name = "brinekPublicSubnetB"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "brinek_igw" {
  vpc_id = aws_vpc.brinek_vpc.id
  tags = {
    Name = "BrineK_IGW"
  }
}

# Route Table for Public subnets
resource "aws_route_table" "brinek_public_rt" {
  vpc_id = aws_vpc.brinek_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.brinek_igw.id
  }
  tags = {
    Name = "brinekPublicRT"
  }
}

resource "aws_route_table_association" "brinek_public_assoc_a" {
  subnet_id      = aws_subnet.brinek_public_subnet_a.id
  route_table_id = aws_route_table.brinek_public_rt.id
}

resource "aws_route_table_association" "brinek_public_assoc_b" {
  subnet_id      = aws_subnet.brinek_public_subnet_b.id
  route_table_id = aws_route_table.brinek_public_rt.id
}

# Security Group equivalent to NSG
resource "aws_security_group" "brinek_sg" {
  name        = "BrineK_SG"
  description = "Security group for BrineK"
  vpc_id      = aws_vpc.brinek_vpc.id

  ingress {
    description = "Allow SSH from specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["40.143.44.44/32"]
  }

  ingress {
    description = "Allow RDP from specific IP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["40.143.44.44/32"]
  }

  ingress {
    description = "Allow WinRM (HTTP)"
    from_port   = 5985
    to_port     = 5985
    protocol    = "tcp"
    cidr_blocks = ["40.143.44.44/32"]
  }

  ingress {
    description = "Allow WinRM (HTTPS)"
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["40.143.44.44/32"]
  }

  # Add ingress rules for CloudLens Manager subnets if required
  ingress {
    description = "Allow CloudLens Manager Subnets"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24", "10.0.3.0/24"]  # Replace with actual CloudLens subnets
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "BrineK_SG"
  }
}

# Key Pair for SSH
resource "aws_key_pair" "brinek_key" {
  key_name   = "brinek_key"
  public_key = file("/Users/brinketu/Downloads/eks-terraform-key.pub")
}

# Ubuntu EC2 Instances
resource "aws_instance" "ubuntu_vm" {
  count         = var.ubuntu_vm_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.large"
  subnet_id     = aws_subnet.brinek_public_subnet_a.id # Use subnet A
  key_name      = aws_key_pair.brinek_key.key_name
  vpc_security_group_ids = [aws_security_group.brinek_sg.id]

  user_data = <<-EOF
            #!/bin/bash
            sudo apt-get update -y
            sudo apt-get install -y nginx
          EOF

  tags = {
    Name = "UbuntuVM-${count.index}"
    Env  = "Development"
  }
}

# Redhat EC2 Instances
resource "aws_instance" "rhel_vm" {
  count         = var.rhel_vm_count
  ami           = var.rhel_ami_id
  instance_type = "t3.large"  # Updated instance type to meet CPU and memory requirements (4 vCPUs, 16 GB RAM)
  subnet_id     = aws_subnet.brinek_public_subnet_a.id # Use subnet A
  key_name      = aws_key_pair.brinek_key.key_name
  vpc_security_group_ids = [
    aws_security_group.brinek_sg.id
  ]
  root_block_device {
    volume_size = 20 
  }

  tags = {
    Name = "RHELVM-${count.index}"
    Env  = "Development"
  }
}

# Windows EC2 Instances
resource "aws_instance" "windows_vm" {
  count         = var.windows_vm_count
  ami           = data.aws_ami.windows.id
  instance_type = "t3.large"
  subnet_id     = aws_subnet.brinek_public_subnet_b.id
  key_name      = aws_key_pair.brinek_key.key_name
  vpc_security_group_ids = [aws_security_group.brinek_sg.id]

user_data = <<-EOF
  <powershell>
  # Enable RDP
  Set-ItemProperty -Path "HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server" -Name "fDenyTSConnections" -Value 0

  # Enable Remote Desktop firewall rule
  Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

  # Optional: Set RDP to allow Network Level Authentication (NLA) - recommended
  Set-ItemProperty -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Terminal Server\\WinStations\\RDP-Tcp" -Name "UserAuthentication" -Value 1

  # Create a new local user 'brine' with password 'Bravedemo123.'
  $password = ConvertTo-SecureString "Bravedemo123." -AsPlainText -Force
  New-LocalUser "brine" -Password $password -FullName "Brine User" -Description "Custom RDP User"
  Add-LocalGroupMember -Group "Administrators" -Member "brine"

  # Optional: Restart Remote Desktop service
  Restart-Service -Name TermService -Force

  </powershell>
EOF


#Enable winrm on Windows after deployment 
  # Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ansible/ansible/stable-2.9/examples/scripts/ConfigureRemotingForAnsible.ps1" -OutFile "C:\\ConfigureRemotingForAnsible.ps1"
  # powershell -ExecutionPolicy Unrestricted -File C:\\ConfigureRemotingForAnsible.ps1

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
output "ubuntu_public_ips" {
  value = [for i in range(length(aws_instance.ubuntu_vm)) : aws_instance.ubuntu_vm[i].public_ip]
}

output "rhel_public_ips" {
  value = [for i in range(length(aws_instance.rhel_vm)) : aws_instance.rhel_vm[i].public_ip]
}

output "rdp_commands_windows" {
  value = [for i in range(length(aws_instance.windows_vm)) : "mstsc /v:${aws_instance.windows_vm[i].public_ip}"]
}

output "windows_public_ips" {
  value = [for i in range(length(aws_instance.windows_vm)) : aws_instance.windows_vm[i].public_ip]
}

output "ssh_instructions_ubuntu" {
  description = "SSH command(s) for Ubuntu VMs"
  value = [
    for i in range(length(aws_instance.ubuntu_vm)) :
    "ssh -i eks-terraform-key.pem ubuntu@${aws_instance.ubuntu_vm[i].public_ip}"
  ]
}

output "ssh_instructions_rhel" {
  description = "SSH command(s) for RHEL VMs"
  value = [
    for i in range(length(aws_instance.rhel_vm)) :
    "ssh -i eks-terraform-key.pem ec2-user@${aws_instance.rhel_vm[i].public_ip}"
  ]
}

output "ansible_inventory" {
  value = join("\n", concat(
    ["[ubuntu_vms]"],
    [for i in range(length(aws_instance.ubuntu_vm)) :
      "ubuntu${i + 1} ansible_host=${aws_instance.ubuntu_vm[i].public_ip}"
    ],
    ["", "[redhat_vms]"],
    [for i in range(length(aws_instance.rhel_vm)) :
      "rhel${i + 1} ansible_host=${aws_instance.rhel_vm[i].public_ip}"

    ],

    ["", "[windows]"],

    [for i in range(length(aws_instance.windows_vm)) :
      aws_instance.windows_vm[i].public_ip
    ],

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

#use this to generat AMIS for RHEL 8.x
# aws ec2 describe-images \                                                                                        ─╯
#   --owners 309956199498 \
#   --filters "Name=name,Values=RHEL-8*HVM*x86_64*" "Name=state,Values=available" \
#   --region us-west-2 \
#   --query "sort_by(Images, &CreationDate)[].{Name:Name,ImageId:ImageId,Date:CreationDate}" \
#   --output table \
#   --profile AdministratorAccess-223117700463

