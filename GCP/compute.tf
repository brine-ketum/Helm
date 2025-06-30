terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

provider "google" {
  # credentials will be read from GOOGLE_APPLICATION_CREDENTIALS environment variable
  project = "poc-project-463913"    # Your POC project ID
  region  = "us-east1"            # Default region for resources
  zone    = "us-east1-b"        # Default zone for resources
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

# Create VPC Network
resource "google_compute_network" "brinek_vpc" {
  name                    = "brinek-vpc"
  auto_create_subnetworks = false
}

# Create Subnets
resource "google_compute_subnetwork" "brinek_subnet_a" {
  name          = "brinek-subnet-a"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-east1"
  network       = google_compute_network.brinek_vpc.id
}

resource "google_compute_subnetwork" "brinek_subnet_b" {
  name          = "brinek-subnet-b"
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-east1"
  network       = google_compute_network.brinek_vpc.id
}

# Firewall Rules (equivalent to AWS Security Groups)
resource "google_compute_firewall" "brinek_ssh" {
  name    = "brinek-allow-ssh"
  network = google_compute_network.brinek_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["40.143.44.44/32"]  # Replace with your IP
  target_tags   = ["brinek-vm"]
}

resource "google_compute_firewall" "brinek_rdp" {
  name    = "brinek-allow-rdp"
  network = google_compute_network.brinek_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["40.143.44.44/32"]  # Replace with your IP
  target_tags   = ["brinek-vm"]
}

resource "google_compute_firewall" "brinek_winrm" {
  name    = "brinek-allow-winrm"
  network = google_compute_network.brinek_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["5985", "5986"]
  }

  source_ranges = ["40.143.44.44/32"]  # Replace with your IP
  target_tags   = ["brinek-vm"]
}

resource "google_compute_firewall" "brinek_internal" {
  name    = "brinek-allow-internal"
  network = google_compute_network.brinek_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  source_ranges = ["10.0.0.0/16"]
  target_tags   = ["brinek-vm"]
}

resource "google_compute_firewall" "brinek_egress" {
  name      = "brinek-allow-egress"
  network   = google_compute_network.brinek_vpc.name
  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
  target_tags        = ["brinek-vm"]
}


resource "google_compute_firewall" "brinek_https_icmp" {
  name    = "brinek-allow-https-icmp"
  network = google_compute_network.brinek_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]  # Or restrict to a specific range
}

# Ubuntu VM Startup Script
locals {

  windows_startup_script = <<-EOF
    <powershell>
    # Set execution policy
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

    # Enable RDP
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1

    # Create admin user with proper settings
    $password = ConvertTo-SecureString "Bravedemo123." -AsPlainText -Force
    New-LocalUser "brine" -Password $password -FullName "Brine User" -PasswordNeverExpires -ErrorAction SilentlyContinue
    Add-LocalGroupMember -Group "Administrators" -Member "brine" -ErrorAction SilentlyContinue

    # CONFIGURE WINRM FOR ANSIBLE
    try {
        # Enable PowerShell Remoting
        Enable-PSRemoting -Force
        
        # Configure WinRM
        winrm quickconfig -quiet -transport:http
        winrm set winrm/config/service/auth '@{Basic="true"}'
        winrm set winrm/config/service '@{AllowUnencrypted="true"}'
        winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="512"}'
        
        # Create HTTP listener for all addresses
        winrm delete winrm/config/listener?Address=*+Transport=HTTP -ErrorAction SilentlyContinue
        winrm create winrm/config/listener?Address=*+Transport=HTTP
        
        # Configure Windows Firewall for WinRM
        New-NetFirewallRule -DisplayName "WinRM-HTTP-In" -Direction Inbound -LocalPort 5985 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
        
        # Restart WinRM service
        Restart-Service WinRM -Force
        
        Write-Output "WinRM configured successfully for Ansible"
    } catch {
        Write-Output "Error configuring WinRM: $_"
    }

    # Log completion
    $logContent = "Windows configuration completed at $(Get-Date)"
    $logContent | Out-File -FilePath "C:\userdata-log.txt" -Encoding UTF8

    # Restart Terminal Services
    Restart-Service TermService -Force
    </powershell>
  EOF
}

# Ubuntu VMs
resource "google_compute_instance" "ubuntu_vm" {
  count        = var.ubuntu_vm_count
  name         = "ubuntu-vm-${count.index}"
  machine_type = "n2-standard-2"  # 2 vCPUs, 8 GB RAM
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    network    = google_compute_network.brinek_vpc.name
    subnetwork = google_compute_subnetwork.brinek_subnet_a.name
    access_config {
      # This gives the VM a public IP address
    }
  }

  metadata = {
    ssh-keys = "brinendamketum:${file("~/.ssh/gcp-key.pub")}"
  }

  tags = ["brinek-vm"]

  labels = {
    name = "ubuntuvm-${count.index}"
    env  = "prod"
    os   = "ubuntu"
  }
}

# RHEL VMs
resource "google_compute_instance" "rhel_vm" {
  count        = var.rhel_vm_count
  name         = "rhel-vm-${count.index}"
  machine_type = "n1-standard-4"  # 4 vCPUs, 15 GB RAM
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image = "rhel-cloud/rhel-8"
      size  = 20
    }
  }

  network_interface {
    network    = google_compute_network.brinek_vpc.name
    subnetwork = google_compute_subnetwork.brinek_subnet_a.name
    access_config {
      # This gives the VM a public IP address
    }
  }

  metadata = {
    ssh-keys = "brinendamketum:${file("~/.ssh/gcp-key.pub")}"
  }

  tags = ["brinek-vm"]

  labels = {
    name = "rhelvm-${count.index}"
    env  = "prod"
    os   = "rhel"
  }
}

#CLMS 
resource "google_compute_instance" "clms_vm" {
  name         = "clms-vm"
  machine_type = "n2-standard-8"  # 8 vCPUs, 32 GB RAM
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
      size  = 200  # 200 GB disk space
    }
  }

  network_interface {
    network    = google_compute_network.brinek_vpc.name
    subnetwork = google_compute_subnetwork.brinek_subnet_a.name
    access_config {
      # Assign public IP
    }
  }

  metadata = {
    ssh-keys = "brinendamketum:${file("~/.ssh/gcp-key.pub")}"
  }

  tags = ["brinek-vm", "clms"]

  labels = {
    name = "clms"
    role = "cloudlens-manager"

  }
}

# Windows VMs
resource "google_compute_instance" "windows_vm" {
  count        = var.windows_vm_count
  name         = "windows-vm-${count.index}"
  machine_type = "n1-standard-4"  # 4 vCPUs, 15 GB RAM
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image = "windows-cloud/windows-server-2022-dc-v20240214"
      size  = 50
    }
  }

  network_interface {
    network    = google_compute_network.brinek_vpc.name
    subnetwork = google_compute_subnetwork.brinek_subnet_b.name
    access_config {
      # This gives the VM a public IP address
    }
  }

  metadata = {
    windows-startup-script-ps1 = local.windows_startup_script
  }

  tags = ["brinek-vm"]

  labels = {
    name = "windowsvm-${count.index}"
    env  = "prod"
    os   = "windows"
  }
}

# Outputs
output "ubuntu_public_ips" {
  value = [for i in range(length(google_compute_instance.ubuntu_vm)) : google_compute_instance.ubuntu_vm[i].network_interface[0].access_config[0].nat_ip]
}

output "rhel_public_ips" {
  value = [for i in range(length(google_compute_instance.rhel_vm)) : google_compute_instance.rhel_vm[i].network_interface[0].access_config[0].nat_ip]
}

output "windows_public_ips" {
  value = [for i in range(length(google_compute_instance.windows_vm)) : google_compute_instance.windows_vm[i].network_interface[0].access_config[0].nat_ip]
}

output "rdp_commands_windows" {
  value = [for i in range(length(google_compute_instance.windows_vm)) : "mstsc /v:${google_compute_instance.windows_vm[i].network_interface[0].access_config[0].nat_ip}"]
}

output "ssh_instructions_ubuntu" {
  description = "SSH command(s) for Ubuntu VMs"
  value = [
    for i in range(length(google_compute_instance.ubuntu_vm)) :
    "ssh -i ~/.ssh/gcp-key brinendamketum@${google_compute_instance.ubuntu_vm[i].network_interface[0].access_config[0].nat_ip}"
  ]
}

output "ssh_instructions_rhel" {
  description = "SSH command(s) for RHEL VMs"
  value = [
    for i in range(length(google_compute_instance.rhel_vm)) :
    "ssh -i ~/.ssh/gcp-key brinendamketum@${google_compute_instance.rhel_vm[i].network_interface[0].access_config[0].nat_ip}"
  ]
}

output "ssh_instructions_clms" {
  description = "SSH command for CLMS VM"
  value       = "ssh -i ~/.ssh/gcp-key brinendamketum@${google_compute_instance.clms_vm.network_interface[0].access_config[0].nat_ip}"
}

output "clms_vm_public_ip" {
  value = google_compute_instance.clms_vm.network_interface[0].access_config[0].nat_ip
}

output "ansible_inventory" {
  value = join("\n", concat(
    ["[ubuntu_vms]"],
    [for i in range(length(google_compute_instance.ubuntu_vm)) :
      "ubuntu${i + 1} ansible_host=${google_compute_instance.ubuntu_vm[i].network_interface[0].access_config[0].nat_ip} ansible_user=brinendamketum"
    ],
    ["", "[redhat_vms]"],
    [for i in range(length(google_compute_instance.rhel_vm)) :
      "rhel${i + 1} ansible_host=${google_compute_instance.rhel_vm[i].network_interface[0].access_config[0].nat_ip} ansible_user=brinendamketum"
    ],
    ["", "[windows]"],
    [for i in range(length(google_compute_instance.windows_vm)) :
      google_compute_instance.windows_vm[i].network_interface[0].access_config[0].nat_ip
    ],
    ["", "[windows:vars]"],
    [
      "ansible_user=brine",
      "ansible_password=Bravedemo123.",
      "ansible_connection=winrm",
      "ansible_winrm_transport=ntlm",
      "ansible_winrm_server_cert_validation=ignore"
    ],
    ["", "[ubuntu_vms:vars]"],
    [
      "ansible_ssh_private_key_file=~/.ssh/gcp-key",
      "ansible_ssh_common_args='-o StrictHostKeyChecking=no'"
    ],
    ["", "[redhat_vms:vars]"],
    [
      "ansible_ssh_private_key_file=~/.ssh/gcp-key",
      "ansible_ssh_common_args='-o StrictHostKeyChecking=no'"
    ]
  ))
}