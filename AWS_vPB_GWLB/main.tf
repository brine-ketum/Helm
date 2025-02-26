provider "aws" {
  region = var.aws_region
  profile = var.profile
}

# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = var.vpc_name
    Env  = var.env
  }
}

# Subnets for Management, Traffic, and Tools
resource "aws_subnet" "mgmt_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = var.mgmt_subnet_cidr
  availability_zone = var.availability_zone
  tags = {
    Name = var.mgmt_subnet_name
    Env  = var.env
  }
}

resource "aws_subnet" "traffic_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = var.traffic_subnet_cidr
  availability_zone = var.availability_zone
  tags = {
    Name = var.traffic_subnet_name
    Env  = var.env
  }
}

resource "aws_subnet" "tools_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = var.tools_subnet_cidr
  availability_zone = var.availability_zone
  tags = {
    Name = var.tools_subnet_name
    Env  = var.env
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "IGW-${var.vpc_name}"
  }
}

# NAT Gateway for Management Subnet
resource "aws_eip" "nat_eip" {
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.mgmt_subnet.id

  tags = {
    Name = "NAT-${var.vpc_name}"
  }
}


# Route Table for VPC
resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Main-RT"
  }
}

# Route Table Association for Management Subnet
resource "aws_route_table_association" "mgmt_subnet_assoc" {
  subnet_id      = aws_subnet.mgmt_subnet.id
  route_table_id = aws_route_table.main_rt.id
}

# Security Group for Instances
resource "aws_security_group" "instance_sg" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    description      = "Allow SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Instance-SG"
  }
}
