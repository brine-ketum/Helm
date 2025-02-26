# AWS General Information
variable "aws_region" {
  type        = string
  description = "AWS Region for the resources"
}

variable "profile" {
  type        = string
  description = "AWS profile for the resources"
}
# VPC and Subnet Information
variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "mgmt_subnet_name" {
  type        = string
  description = "Name of the management subnet"
}

variable "mgmt_subnet_cidr" {
  type        = string
  description = "CIDR block for the management subnet"
}

variable "traffic_subnet_name" {
  type        = string
  description = "Name of the traffic subnet"
}

variable "traffic_subnet_cidr" {
  type        = string
  description = "CIDR block for the traffic subnet"
}

variable "tools_subnet_name" {
  type        = string
  description = "Name of the tools subnet"
}

variable "tools_subnet_cidr" {
  type        = string
  description = "CIDR block for the tools subnet"
}

variable "availability_zone" {
  type        = string
  description = "AWS Availability Zone"
}

# Security Group Information
variable "instance_sg_name" {
  type        = string
  description = "Name of the security group for the instances"
}

# Gateway Load Balancer (GWLB) Information
variable "gwlb_name" {
  type        = string
  description = "Name of the Gateway Load Balancer"
}

variable "gwlb_probe_name" {
  type        = string
  description = "Name of the health check (probe) for GWLB"
}

variable "gwlb_probe_port" {
  type        = number
  description = "Port for the health check (probe) for GWLB"
}

variable "gwlb_probe_protocol" {
  type        = string
  description = "Protocol for the health check (probe) for GWLB"
}

variable "gwlb_probe_interval" {
  type        = number
  description = "Interval (in seconds) for the GWLB health check (probe)"
}

variable "gwlb_probe_count" {
  type        = number
  description = "Number of healthy checks before the instance is considered healthy"
}

variable "gwlb_lb_rule_name" {
  type        = string
  description = "Name of the GWLB Load Balancer Rule"
}

variable "gwlb_rule_protocol" {
  type        = string
  description = "Protocol for the GWLB Load Balancer Rule"
}

variable "gwlb_rule_frontend_port" {
  type        = number
  description = "Frontend port for the GWLB Load Balancer Rule"
}

# EC2 Information for vPacketStack
variable "vm_instance_type" {
  type        = string
  description = "Instance type for the EC2 instances"
}

variable "vm_key_name" {
  type        = string
  description = "Key pair name for SSH access to EC2 instances"
}

variable "vm_image_id" {
  type        = string
  description = "AMI ID for the EC2 instances"
}

# OS Disk Information
variable "os_disk_size_gb" {
  type        = number
  description = "Size of the OS disk in GB for the EC2 instances"
}

# Environment Information
variable "env" {
  type        = string
  description = "Environment name (e.g., dev, production)"
}
