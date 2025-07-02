# environments/prod/main.tf

terraform {
  required_version = ">= 1.0"
}

# Provider Configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

# Local variables
locals {
  environment = "prod"
  common_tags = ["brinek-vm", local.environment]
  
  # VM configurations - ALL must have exactly the same fields
  ubuntu_vms = {
    for i in range(var.ubuntu_vm_count) : "ubuntu-vm-${i}" => {
      machine_type = "n2-standard-2"
      zone         = "${var.region}-b"
      os_type      = "linux"
      source_image = ""
      source_image_family = "ubuntu-2204-lts"
      source_image_project = "ubuntu-os-cloud"
      boot_disk_size = 20
      boot_disk_type = "pd-standard"
      enable_public_ip = true
      tags = []
      metadata = {}
      labels = {
        name = "ubuntuvm-${i}"
        env  = local.environment
        os   = "ubuntu"
      }
    }
  }
  
  rhel_vms = {
    for i in range(var.rhel_vm_count) : "rhel-vm-${i}" => {
      machine_type = "n1-standard-4"
      zone         = "${var.region}-b"
      os_type      = "linux"
      source_image = ""
      source_image_family = "rhel-8"
      source_image_project = "rhel-cloud"
      boot_disk_size = 20
      boot_disk_type = "pd-standard"
      enable_public_ip = true
      tags = []
      metadata = {}
      labels = {
        name = "rhelvm-${i}"
        env  = local.environment
        os   = "rhel"
      }
    }
  }
  
  windows_vms = {
    for i in range(var.windows_vm_count) : "windows-vm-${i}" => {
      machine_type = "n1-standard-4"
      zone         = "${var.region}-b"
      os_type      = "windows"
      source_image = ""
      source_image_family = "windows-2022"
      source_image_project = "windows-cloud"
      boot_disk_size = 50
      boot_disk_type = "pd-standard"
      enable_public_ip = true
      tags = []
      metadata = {}
      labels = {
        name = "windowsvm-${i}"
        env  = local.environment
        os   = "windows"
      }
    }
  }
  
  # Combine all VMs
  all_vms = merge(local.ubuntu_vms, local.rhel_vms, local.windows_vms)
}

# Networking Module
module "networking" {
  source = "../../modules/networking"
  
  vpc_name        = "${var.name_prefix}-vpc"
  vpc_description = "VPC for ${var.name_prefix} ${local.environment} environment"
  routing_mode    = "REGIONAL"
  
  subnets = {
    "${var.name_prefix}-subnet-a" = {
      ip_cidr_range    = "10.0.1.0/24"
      region           = var.region
      description      = "Subnet A for ${local.environment}"
      enable_flow_logs = var.enable_flow_logs
    }
    "${var.name_prefix}-subnet-b" = {
      ip_cidr_range    = "10.0.2.0/24"
      region           = var.region
      description      = "Subnet B for ${local.environment}"
      enable_flow_logs = var.enable_flow_logs
    }
  }
  
  create_nat_gateway = var.create_nat_gateway
  nat_region        = var.region
}

# Security Module
module "security" {
  source = "../../modules/security"
  
  network_name = module.networking.vpc_name
  target_tags  = local.common_tags
  
  ssh_source_ranges   = var.allowed_ssh_ips
  rdp_source_ranges   = var.allowed_rdp_ips
  winrm_source_ranges = var.allowed_winrm_ips
  internal_ranges     = ["10.0.0.0/16"]
  
  custom_firewall_rules = {
    allow-https-icmp = {
      description = "Allow HTTPS and ICMP from anywhere"
      direction   = "INGRESS"
      priority    = 1000
      source_ranges = ["0.0.0.0/0"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["443"]
        },
        {
          protocol = "icmp"
          ports    = []
        }
      ]
    }
  }
}

# Compute Module for all VMs
module "compute" {
  source = "../../modules/compute"
  
  project_id  = var.project_id
  name_prefix = var.name_prefix
  region      = var.region
  zone        = "${var.region}-b"
  
  network    = module.networking.vpc_name
  subnetwork = module.networking.subnet_self_links["${var.name_prefix}-subnet-a"]
  
  network_tags = local.common_tags
  
  ssh_username   = var.ssh_username
  ssh_public_key = file(var.ssh_public_key_path)
  
  instances = local.all_vms
  
  labels = {
    environment = local.environment
    managed_by  = "terraform"
  }
}

# Special CLMS VM
module "clms_compute" {
  source = "../../modules/compute"
  
  project_id  = var.project_id
  name_prefix = "clms"
  region      = var.region
  zone        = "${var.region}-b"
  
  network    = module.networking.vpc_name
  subnetwork = module.networking.subnet_self_links["${var.name_prefix}-subnet-a"]
  
  network_tags = concat(local.common_tags, ["clms"])
  
  ssh_username   = var.ssh_username
  ssh_public_key = file(var.ssh_public_key_path)
  
  instances = {
    "clms-vm" = {
      machine_type = "n2-standard-8"
      zone         = "${var.region}-b"
      os_type      = "linux"
      source_image = ""
      source_image_family = "ubuntu-2204-lts"
      source_image_project = "ubuntu-os-cloud"
      boot_disk_size = 200
      boot_disk_type = "pd-standard"
      enable_public_ip = true
      tags = []
      metadata = {}
      labels = {
        name = "clms"
        role = "cloudlens-manager"
      }
    }
  }
  
  labels = {
    environment = local.environment
    managed_by  = "terraform"
  }
}