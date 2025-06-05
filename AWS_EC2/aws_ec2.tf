# provider "aws" {
#   region  = "us-east-1" # Choose your AWS region
#   profile = "brine"
# }
# # Create the IAM policy
# resource "aws_iam_policy" "cloudlens_metadata_policy" {
#   name        = "cloudlens_metadata_policy"
#   description = "Policy to allow CloudLens agent to extract EC2 metadata and manage traffic mirroring."
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "DescribeActions",
#       "Effect": "Allow",
#       "Action": [
#         "ec2:Describe*"
#       ],
#       "Resource": "*"
#     }
#   ]
# }
# EOF
# }


# # Create the IAM role
# resource "aws_iam_role" "cloudlens_ec2_role" {
#   name               = "cloudlens_ec2_role"
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# EOF
# }

# # Attach the IAM policy to the IAM role
# resource "aws_iam_role_policy_attachment" "cloudlens_policy_attachment" {
#   role       = aws_iam_role.cloudlens_ec2_role.name
#   policy_arn = aws_iam_policy.cloudlens_metadata_policy.arn
# }

# # Create an instance profile to attach the IAM role to the EC2 instance
# resource "aws_iam_instance_profile" "cloudlens_instance_profile" {
#   name = "cloudlens_instance_profile"
#   role = aws_iam_role.cloudlens_ec2_role.name
# }

# # Create a VPC with a broad CIDR block
# resource "aws_vpc" "demo_cloudlens_main_vpc" {
#   cidr_block = "10.0.0.0/16" 

#   tags = {
#     Name = "demo_cloudlens_main_vpc"
#   }
# }


# # Create a Subnet with a valid CIDR block
# resource "aws_subnet" "demo_cloudlens_main_public_subnet" {
#   vpc_id            = aws_vpc.demo_cloudlens_main_vpc.id
#   cidr_block        = "10.0.1.0/24"  # Example valid subnet within the VPC CIDR block
#   availability_zone = "us-east-1a"    # Choose your AZ
# }

# # Create an Internet Gateway
# resource "aws_internet_gateway" "demo_cloudlens_main_igw" {
#   vpc_id = aws_vpc.demo_cloudlens_main_vpc.id
# }

# # Create a Route Table for the subnet
# resource "aws_route_table" "demo_cloudlens_main_route_table" {
#   vpc_id = aws_vpc.demo_cloudlens_main_vpc.id

#   # Route all outbound internet traffic through the Internet Gateway
#   route {
#     cidr_block = "0.0.0.0/0"  # Allow all internet traffic
#     gateway_id = aws_internet_gateway.demo_cloudlens_main_igw.id
#   }
# }

# # Associate the Route Table with the Subnet
# resource "aws_route_table_association" "demo_cloudlens_subnet_association" {
#   subnet_id      = aws_subnet.demo_cloudlens_main_public_subnet.id
#   route_table_id = aws_route_table.demo_cloudlens_main_route_table.id
# }

# # Create a Security Group to allow all inbound and outbound traffic
# resource "aws_security_group" "demo_cloudlens_allow_all_traffic" {
#   vpc_id = aws_vpc.demo_cloudlens_main_vpc.id
#   name   = "demo_cloudlens-allow-all-traffic"

#   # Allow all inbound traffic
#   ingress {
#     from_port   = 0
#     to_port     = 65535
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # Allow all IP addresses
#   }

#   ingress {
#     from_port   = 0
#     to_port     = 65535
#     protocol    = "udp"
#     cidr_blocks = ["0.0.0.0/0"] # Allow all IP addresses
#   }

#   # Allow all outbound traffic
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"  # All protocols
#     cidr_blocks = ["0.0.0.0/0"] # Allow all IP addresses
#   }
# }


# resource "aws_lb" "demo_nlb" {
#   name               = "demo-cloudlens-nlb"
#   internal           = false
#   load_balancer_type = "network"
#   subnets            = [aws_subnet.demo_cloudlens_main_public_subnet.id]
# }

# resource "aws_lb_target_group" "webserver1_tg" {
#   name     = "webserver1-tg"
#   port     = 22
#   protocol = "TCP"
#   vpc_id   = aws_vpc.demo_cloudlens_main_vpc.id
# }

# resource "aws_lb_target_group" "webserver2_tg" {
#   name     = "webserver2-tg"
#   port     = 22
#   protocol = "TCP"
#   vpc_id   = aws_vpc.demo_cloudlens_main_vpc.id
# }

# # Target groups for other VMs (Tool, VPB)
# # Assume demo_cloudlens_tool_instance and demo_cloudlens_vpb_instance are defined

# resource "aws_lb_target_group_attachment" "webserver1_attachment" {
#   target_group_arn = aws_lb_target_group.webserver1_tg.arn
#   target_id        = aws_instance.demo_cloudlens_ubuntu_instance.id
#   port             = 22
# }

# resource "aws_lb_target_group_attachment" "webserver2_attachment" {
#   target_group_arn = aws_lb_target_group.webserver2_tg.arn
#   target_id        = aws_instance.demo_cloudlens_windows_instance.id
#   port             = 22
# }

# resource "aws_lb_listener" "webserver1_listener" {
#   load_balancer_arn = aws_lb.demo_nlb.arn
#   port              = 60001
#   protocol          = "TCP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.webserver1_tg.arn
#   }
# }

# resource "aws_lb_listener" "webserver2_listener" {
#   load_balancer_arn = aws_lb.demo_nlb.arn
#   port              = 60002
#   protocol          = "TCP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.webserver2_tg.arn
#   }
# }

# # Create an Ubuntu EC2 instance
# resource "aws_instance" "demo_cloudlens_ubuntu_instance" {
#   ami                    = "ami-0dba2cb6798deb6d8" # Ubuntu 20.04 AMI ID (Update for your region)
#   instance_type          = "t3.2xlarge"             
#   vpc_security_group_ids = [aws_security_group.demo_cloudlens_allow_all_traffic.id]
#   subnet_id              = aws_subnet.demo_cloudlens_main_public_subnet.id
  
#   key_name               = "eks-terraform-key"    # Replace with your key pair

#   # Assign a public IP
#   associate_public_ip_address = true

#   # Add 20GB of EBS storage
#   root_block_device {
#     volume_size           = 250                       # 20GB storage
#     volume_type           = "gp2"
#     delete_on_termination = true
#   }

#   # User Data (optional script to install packages, e.g., Apache)
#   user_data = <<-EOF
#               #!/bin/bash
#               sudo apt update
#               sudo apt install -y apache2
#               EOF
#   iam_instance_profile = aws_iam_instance_profile.cloudlens_instance_profile.name

#   tags = {
#     Name = "demo_cloudlens_ubuntuinstance" 
#     Env  = "demo"
#   }
# }

# # Create a Windows EC2 instance
# resource "aws_instance" "demo_cloudlens_windows_instance" {
#   ami                    = "ami-0b69ea66ff7391e80" # Windows Server 2019 Base AMI (Update for your region)
#   instance_type          = "t3.2xlarge"             
#   vpc_security_group_ids = [aws_security_group.demo_cloudlens_allow_all_traffic.id]
#   subnet_id              = aws_subnet.demo_cloudlens_main_public_subnet.id
  
#   key_name               = "eks-terraform-key"    # Replace with your key pair

#   # Assign a public IP
#   associate_public_ip_address = true

#   # Add 20GB of EBS storage
#   root_block_device {
#     volume_size           = 20                       # 20GB storage
#     volume_type           = "gp2"
#     delete_on_termination = true
#   }

#   # User Data (optional script for Windows initialization)
#   user_data = <<-EOF
#               <powershell>
#               Install-WindowsFeature -Name Web-Server
#               </powershell>
#               EOF
#   iam_instance_profile = aws_iam_instance_profile.cloudlens_instance_profile.name

#   tags = {
#     Name = "demo_cloudlens_WindowsInstance"
#     Env  = "demo"
#   }
# }

# # Create a Red Hat Linux EC2 instance
# resource "aws_instance" "demo_cloudlens_rhel_instance" {
#   ami                    = "ami-0583d8c7a9c35822c" # Replace with your region's RedHat 7 or 8 AMI
#   instance_type          = "t3.xlarge"             # t3.xlarge = 4 vCPU, 16GB RAM
#   vpc_security_group_ids = [aws_security_group.demo_cloudlens_allow_all_traffic.id]
#   subnet_id              = aws_subnet.demo_cloudlens_main_public_subnet.id
#   key_name               = "eks-terraform-key"

#   associate_public_ip_address = true

#   root_block_device {
#     volume_size           = 100                    # Minimum 100GB as per requirement
#     volume_type           = "gp2"
#     delete_on_termination = true
#   }

#   user_data = <<-EOF
#               #!/bin/bash
#               sudo yum update -y

#               # Install required packages
#               sudo yum install -y wget curl policycoreutils-python

#               # Install SNAP (for CentOS/RHEL 7 or 8)
#               sudo yum install -y epel-release
#               sudo yum install -y snapd
#               sudo systemctl enable --now snapd.socket
#               sudo ln -s /var/lib/snapd/snap /snap

#               # Enable SELinux module for snap if required
#               sudo setsebool -P selinuxuser_execmod 1

#               # Reboot is needed after SNAP installation
#               (sleep 1 && reboot) &
#               EOF

#   iam_instance_profile = aws_iam_instance_profile.cloudlens_instance_profile.name

#   tags = {
#     Name = "demo_cloudlens_RHELInstance"
#     Env  = "demo"
#     Role = "CloudLensManager"
#   }
# }

# # Create an Amazon Linux 2023 EC2 instance
# # resource "aws_instance" "demo_cloudlens_amazon_linux_2023_instance" {
# #   depends_on = [
# #     aws_security_group.demo_cloudlens_allow_all_traffic,
# #     aws_subnet.demo_cloudlens_main_public_subnet
# #   ]
# #   ami                    = "ami-012967cc5a8c9f891"
# #   instance_type          = "t3.large"
# #   vpc_security_group_ids = [aws_security_group.demo_cloudlens_allow_all_traffic.id]
# #   subnet_id              = aws_subnet.demo_cloudlens_main_public_subnet.id
# #   key_name               = "eks-terraform-key"
# #   associate_public_ip_address = true
# #   root_block_device {
# #     volume_size           = 20
# #     volume_type           = "gp2"
# #     delete_on_termination = true
# #   }
# #   user_data = <<-EOF
# #             #!/bin/bash
# #             sudo dnf update -y
# #             sudo dnf install -y httpd
# #             sudo systemctl start httpd
# #             sudo systemctl enable httpd
# #             EOF

# #   iam_instance_profile = aws_iam_instance_profile.cloudlens_instance_profile.name

# #   metadata_options {
# #     http_endpoint               = "enabled"
# #     http_tokens                 = "optional" # Allows IMDSv1 (default)
# #     http_put_response_hop_limit = 1
# #   }

# #   tags = {
# #     Name = "demo_cloudlens_AmazonLinux2023Instance"
# #     Env  = "demo"
# #   }
# # }


# # Output the Public IP of the Amazon Linux 2023 instance
# # output "demo_cloudlens_amazon_linux_2023_public_ip" {
# #   value = aws_instance.demo_cloudlens_amazon_linux_2023_instance.public_ip
# # }

# # Output the Public IPs of the instances
# output "demo_cloudlens_ubuntu_public_ip" {
#   value = aws_instance.demo_cloudlens_ubuntu_instance.public_ip
# }

# # output "demo_cloudlens_windows_public_ip" {
# #   value = aws_instance.demo_cloudlens_windows_instance.public_ip
# # }

# output "demo_cloudlens_rhel_public_ip" {
#   value = aws_instance.demo_cloudlens_rhel_instance.public_ip
# }

# #SSH to Tool VM (Amazon Linux):   ssh ec2-user@${aws_instance.demo_cloudlens_amazon_linux_2023_instance.public_ip}
# output "ssh_instructions" {
#   value = <<EOF
# SSH to Ubuntu:      ssh ubuntu@${aws_lb.demo_nlb.dns_name} -p 60001
# SSH to WebServer2 (Windows):     Use RDP with key pair 'eks-terraform-key' to connect to ${aws_instance.demo_cloudlens_windows_instance.public_ip}
# SSH to VPB RHEL:               ssh ec2-user@${aws_instance.demo_cloudlens_rhel_instance.public_ip}
# EOF
# }



