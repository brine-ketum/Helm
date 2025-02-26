provider "aws" {
  region  = "us-east-1" # Choose your AWS region
  profile = "brine"
}
# Create the IAM policy
resource "aws_iam_policy" "cloudlens_metadata_policy" {
  name        = "cloudlens_metadata_policy"
  description = "Policy to allow CloudLens agent to extract EC2 metadata and manage traffic mirroring."
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DescribeActions",
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


# Create the IAM role
resource "aws_iam_role" "cloudlens_ec2_role" {
  name               = "cloudlens_ec2_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "cloudlens_policy_attachment" {
  role       = aws_iam_role.cloudlens_ec2_role.name
  policy_arn = aws_iam_policy.cloudlens_metadata_policy.arn
}

# Create an instance profile to attach the IAM role to the EC2 instance
resource "aws_iam_instance_profile" "cloudlens_instance_profile" {
  name = "cloudlens_instance_profile"
  role = aws_iam_role.cloudlens_ec2_role.name
}

# Create a VPC with a broad CIDR block
resource "aws_vpc" "demo_cloudlens_main_vpc" {
  cidr_block = "10.0.0.0/16" 

  tags = {
    Name = "demo_cloudlens_main_vpc"
  }
}


# Create a Subnet with a valid CIDR block
resource "aws_subnet" "demo_cloudlens_main_public_subnet" {
  vpc_id            = aws_vpc.demo_cloudlens_main_vpc.id
  cidr_block        = "10.0.1.0/24"  # Example valid subnet within the VPC CIDR block
  availability_zone = "us-east-1a"    # Choose your AZ
}

# Create an Internet Gateway
resource "aws_internet_gateway" "demo_cloudlens_main_igw" {
  vpc_id = aws_vpc.demo_cloudlens_main_vpc.id
}

# Create a Route Table for the subnet
resource "aws_route_table" "demo_cloudlens_main_route_table" {
  vpc_id = aws_vpc.demo_cloudlens_main_vpc.id

  # Route all outbound internet traffic through the Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"  # Allow all internet traffic
    gateway_id = aws_internet_gateway.demo_cloudlens_main_igw.id
  }
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "demo_cloudlens_subnet_association" {
  subnet_id      = aws_subnet.demo_cloudlens_main_public_subnet.id
  route_table_id = aws_route_table.demo_cloudlens_main_route_table.id
}

# Create a Security Group to allow all inbound and outbound traffic
resource "aws_security_group" "demo_cloudlens_allow_all_traffic" {
  vpc_id = aws_vpc.demo_cloudlens_main_vpc.id
  name   = "demo_cloudlens-allow-all-traffic"

  # Allow all inbound traffic
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow all IP addresses
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"] # Allow all IP addresses
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # All protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow all IP addresses
  }
}

# Create an Ubuntu EC2 instance
resource "aws_instance" "demo_cloudlens_ubuntu_instance" {
  ami                    = "ami-0dba2cb6798deb6d8" # Ubuntu 20.04 AMI ID (Update for your region)
  instance_type          = "t3.2xlarge"             
  vpc_security_group_ids = [aws_security_group.demo_cloudlens_allow_all_traffic.id]
  subnet_id              = aws_subnet.demo_cloudlens_main_public_subnet.id
  
  key_name               = "eks-terraform-key"    # Replace with your key pair

  # Assign a public IP
  associate_public_ip_address = true

  # Add 20GB of EBS storage
  root_block_device {
    volume_size           = 250                       # 20GB storage
    volume_type           = "gp2"
    delete_on_termination = true
  }

  # User Data (optional script to install packages, e.g., Apache)
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt install -y apache2
              EOF
  iam_instance_profile = aws_iam_instance_profile.cloudlens_instance_profile.name

  tags = {
    Name = "demo_cloudlens_ubuntuinstance" 
    Env  = "demo"
  }
}

# Create a Windows EC2 instance
resource "aws_instance" "demo_cloudlens_windows_instance" {
  ami                    = "ami-0b69ea66ff7391e80" # Windows Server 2019 Base AMI (Update for your region)
  instance_type          = "t3.2xlarge"             
  vpc_security_group_ids = [aws_security_group.demo_cloudlens_allow_all_traffic.id]
  subnet_id              = aws_subnet.demo_cloudlens_main_public_subnet.id
  
  key_name               = "eks-terraform-key"    # Replace with your key pair

  # Assign a public IP
  associate_public_ip_address = true

  # Add 20GB of EBS storage
  root_block_device {
    volume_size           = 20                       # 20GB storage
    volume_type           = "gp2"
    delete_on_termination = true
  }

  # User Data (optional script for Windows initialization)
  user_data = <<-EOF
              <powershell>
              Install-WindowsFeature -Name Web-Server
              </powershell>
              EOF
  iam_instance_profile = aws_iam_instance_profile.cloudlens_instance_profile.name

  tags = {
    Name = "demo_cloudlens_WindowsInstance"
    Env  = "demo"
  }
}

# Create a Red Hat Linux EC2 instance
resource "aws_instance" "demo_cloudlens_rhel_instance" {
  ami                    = "ami-0583d8c7a9c35822c" # Replace with the valid AMI ID for RHEL
  instance_type          = "t3.2xlarge"                
  vpc_security_group_ids = [aws_security_group.demo_cloudlens_allow_all_traffic.id]
  subnet_id              = aws_subnet.demo_cloudlens_main_public_subnet.id
  
  key_name               = "eks-terraform-key"   # Replace with your actual key pair name

  # Assign a public IP
  associate_public_ip_address = true

  # Add 20GB of EBS storage
  root_block_device {
    volume_size           = 20                      # 20GB storage
    volume_type           = "gp2"
    delete_on_termination = true
  }

  # User Data to install Apache web server (optional)
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              EOF
  iam_instance_profile = aws_iam_instance_profile.cloudlens_instance_profile.name
  tags = {
    Name = "demo_cloudlens_RHELInstance"
    Env  = "demo"
  }
}

# # Create a CentOS EC2 instance
resource "aws_instance" "demo_cloudlens_centos_instance" {
  ami                    = "ami-052efd3df9dad4825" # Replace with the valid AMI ID for CentOS (update for your region)
  instance_type          = "t3.2xlarge"
  vpc_security_group_ids = [aws_security_group.demo_cloudlens_allow_all_traffic.id]
  subnet_id              = aws_subnet.demo_cloudlens_main_public_subnet.id
  
  key_name               = "eks-terraform-key"   # Replace with your actual key pair name

  # Assign a public IP
  associate_public_ip_address = true

  # Add 20GB of EBS storage
  root_block_device {
    volume_size           = 20                      # 20GB storage
    volume_type           = "gp2"
    delete_on_termination = true
  }

  # User Data to install NGINX web server (optional)
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              EOF
  iam_instance_profile = aws_iam_instance_profile.cloudlens_instance_profile.name

  tags = {
    Name = "demo_cloudlens_CentOSInstance"
    Env  = "demo"
  }
}

# Create a Debian EC2 instance
# resource "aws_instance" "demo_cloudlens_debian_instance" {
#   ami                    = "ami-00514a528eadbc95b" # Replace with the valid AMI ID for Debian (update for your region)
#   instance_type          = "t2.micro"
#   vpc_security_group_ids = [aws_security_group.demo_cloudlens_allow_all_traffic.id]
#   subnet_id              = aws_subnet.demo_cloudlens_main_public_subnet.id
  
#   key_name               = "eks-terraform-key"   # Replace with your actual key pair name

#   # Assign a public IP
#   associate_public_ip_address = true

#   # Add 20GB of EBS storage
#   root_block_device {
#     volume_size           = 20                      # 20GB storage
#     volume_type           = "gp2"
#     delete_on_termination = true
#   }

#   # User Data to install NGINX web server (optional)
#   user_data = <<-EOF
#               #!/bin/bash
#               sudo apt update
#               sudo apt install -y nginx
#               EOF
 # iam_instance_profile = aws_iam_instance_profile.cloudlens_instance_profile.name
#   tags = {
#     Name = "demo_cloudlens_DebianInstance"
#     Env  = "demo"
#   }
# }

# Create an Amazon Linux 2023 EC2 instance
resource "aws_instance" "demo_cloudlens_amazon_linux_2023_instance" {
  depends_on = [
    aws_security_group.demo_cloudlens_allow_all_traffic,
    aws_subnet.demo_cloudlens_main_public_subnet
  ]
  ami                    = "ami-012967cc5a8c9f891"
  instance_type          = "t3.large"
  vpc_security_group_ids = [aws_security_group.demo_cloudlens_allow_all_traffic.id]
  subnet_id              = aws_subnet.demo_cloudlens_main_public_subnet.id
  key_name               = "eks-terraform-key"
  associate_public_ip_address = true
  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }
  user_data = <<-EOF
            #!/bin/bash
            sudo dnf update -y
            sudo dnf install -y httpd
            sudo systemctl start httpd
            sudo systemctl enable httpd
            EOF

  iam_instance_profile = aws_iam_instance_profile.cloudlens_instance_profile.name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional" # Allows IMDSv1 (default)
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "demo_cloudlens_AmazonLinux2023Instance"
    Env  = "demo"
  }
}


# Output the Public IP of the Amazon Linux 2023 instance
output "demo_cloudlens_amazon_linux_2023_public_ip" {
  value = aws_instance.demo_cloudlens_amazon_linux_2023_instance.public_ip
}


# Output the Public IP of the Debian instance
# output "demo_cloudlens_debian_public_ip" {
#   value = aws_instance.demo_cloudlens_debian_instance.public_ip
# }


# Output the Public IP of the CentOS instance
# output "demo_cloudlens_centos_public_ip" {
#   value = aws_instance.demo_cloudlens_centos_instance.public_ip
# }


# Output the Public IPs of the instances
output "demo_cloudlens_ubuntu_public_ip" {
  value = aws_instance.demo_cloudlens_ubuntu_instance.public_ip
}

# output "demo_cloudlens_windows_public_ip" {
#   value = aws_instance.demo_cloudlens_windows_instance.public_ip
# }

# output "demo_cloudlens_rhel_public_ip" {
#   value = aws_instance.demo_cloudlens_rhel_instance.public_ip
# }