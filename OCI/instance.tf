terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 4.0"
    }
  }
}

# Variables for authentication
variable "tenancy_ocid" {
  description = "OCID of the tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the user"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of the API key"
  type        = string
}

variable "private_key_path" {
  description = "Path to the private key file"
  type        = string
}

variable "region" {
  description = "OCI region"
  type        = string
  default     = "us-ashburn-1"
}

variable "compartment_ocid" {
  description = "OCID of the compartment"
  type        = string
}

# Variables for VM counts
variable "ubuntu_vm_count" {
  description = "Number of Ubuntu VMs to create"
  type        = number
  default     = 0
}

variable "rhel_vm_count" {
  description = "Number of RHEL VMs to create"
  type        = number
  default     = 0
}

variable "windows_vm_count" {
  description = "Number of Windows VMs to create"
  type        = number
  default     = 0
}

variable "windows_admin_password" {
  description = "Admin password for the Windows VM"
  type        = string
  default     = "Bravedemo123."
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "/Users/brinketu/Downloads/ssh_key.pub"
}

# Provider configuration
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Get latest images
data "oci_core_images" "ubuntu_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.E4.Flex"
  sort_by                  = "TIMECREATED"
  sort_order              = "DESC"
}

data "oci_core_images" "ol_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = "VM.Standard.E4.Flex"
  sort_by                  = "TIMECREATED"
  sort_order              = "DESC"
}

data "oci_core_images" "windows_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Windows"
  operating_system_version = "Server 2019 Standard"
  shape                    = "VM.Standard.E4.Flex"
  sort_by                  = "TIMECREATED"
  sort_order              = "DESC"
}

# VCN (Virtual Cloud Network)
resource "oci_core_vcn" "brinek_vcn" {
  compartment_id = var.compartment_ocid
  display_name   = "brinekVCN"
  cidr_blocks    = ["10.0.0.0/16"]
  dns_label      = "brinekvcn"
}

# Internet Gateway
resource "oci_core_internet_gateway" "brinek_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.brinek_vcn.id
  display_name   = "BrinekIGW"
}

# Route Table
resource "oci_core_default_route_table" "brinek_rt" {
  manage_default_resource_id = oci_core_vcn.brinek_vcn.default_route_table_id
  display_name               = "BrinekRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.brinek_igw.id
  }
}

# Public Subnet
resource "oci_core_subnet" "brinek_public_subnet" {
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.brinek_vcn.id
  display_name        = "BrinekPublicSubnet"
  cidr_block          = "10.0.1.0/24"
  dns_label           = "publicsubnet"
  security_list_ids   = [oci_core_security_list.brinek_security_list.id]
  route_table_id      = oci_core_vcn.brinek_vcn.default_route_table_id
  dhcp_options_id     = oci_core_vcn.brinek_vcn.default_dhcp_options_id
}

# Security List
resource "oci_core_security_list" "brinek_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.brinek_vcn.id
  display_name   = "BrinekSecurityList"

  # Egress rule - allow all outbound
  egress_security_rules {
    destination      = "0.0.0.0/0"
    protocol         = "all"
    description      = "Allow all outbound traffic"
  }

  # SSH access
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "40.143.44.44/32"
    source_type = "CIDR_BLOCK"
    description = "SSH access"

    tcp_options {
      min = 22
      max = 22
    }
  }

  # RDP access
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "40.143.44.44/32"
    source_type = "CIDR_BLOCK"
    description = "RDP access"

    tcp_options {
      min = 3389
      max = 3389
    }
  }

  # WinRM access
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "40.143.44.44/32"
    source_type = "CIDR_BLOCK"
    description = "WinRM HTTP"

    tcp_options {
      min = 5985
      max = 5985
    }
  }

  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "40.143.44.44/32"
    source_type = "CIDR_BLOCK"
    description = "WinRM HTTPS"

    tcp_options {
      min = 5986
      max = 5986
    }
  }

  # HTTPS access for software installations
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "HTTPS access"

    tcp_options {
      min = 443
      max = 443
    }
  }

  # ICMP for ping
  ingress_security_rules {
    protocol    = "1" # ICMP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "ICMP for ping"
  }
}

# Ubuntu VMs
resource "oci_core_instance" "ubuntu_vm" {
  count               = var.ubuntu_vm_count
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[count.index % length(data.oci_identity_availability_domains.ads.availability_domains)].name
  compartment_id      = var.compartment_ocid
  display_name        = "UbuntuVM-${count.index}"
  shape               = "VM.Standard.E4.Flex"

  shape_config {
    ocpus         = 4
    memory_in_gbs = 16
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.brinek_public_subnet.id
    display_name     = "UbuntuVNIC-${count.index}"
    assign_public_ip = true
    hostname_label   = "ubuntu-${count.index}"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_images.images[0].id
    boot_volume_size_in_gbs = 50
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data = base64encode(<<-EOF
      #!/bin/bash
      useradd -m -s /bin/bash brine
      usermod -aG sudo brine
      mkdir -p /home/brine/.ssh
      echo "${file(var.ssh_public_key_path)}" >> /home/brine/.ssh/authorized_keys
      chown -R brine:brine /home/brine/.ssh
      chmod 700 /home/brine/.ssh
      chmod 600 /home/brine/.ssh/authorized_keys
      echo "brine ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/brine

    EOF
    )
  }

  freeform_tags = {
    "Name" = "UbuntuVM-${count.index}"
    "Env"  = "prod"
    "OS"   = "Ubuntu"
  }
}

# Oracle Linux VMs (replacing RHEL)
resource "oci_core_instance" "ol_vm" {
  count               = var.rhel_vm_count
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[count.index % length(data.oci_identity_availability_domains.ads.availability_domains)].name
  compartment_id      = var.compartment_ocid
  display_name        = "OracleLinuxVM-${count.index}"
  shape               = "VM.Standard.E4.Flex"

  shape_config {
    ocpus         = 4
    memory_in_gbs = 16
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.brinek_public_subnet.id
    display_name     = "OLVNIC-${count.index}"
    assign_public_ip = true
    hostname_label   = "ol-${count.index}"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ol_images.images[0].id
    boot_volume_size_in_gbs = 50
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data = base64encode(<<-EOF
      #!/bin/bash
      useradd -m -s /bin/bash brine
      usermod -aG wheel brine
      mkdir -p /home/brine/.ssh
      echo "${file(var.ssh_public_key_path)}" >> /home/brine/.ssh/authorized_keys
      chown -R brine:brine /home/brine/.ssh
      chmod 700 /home/brine/.ssh
      chmod 600 /home/brine/.ssh/authorized_keys
      echo "brine ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/brine

    EOF
    )
  }

  freeform_tags = {
    "Name" = "OracleLinuxVM-${count.index}"
    "Env"  = "prod"
    "OS"   = "OracleLinux"
  }
}

# CLMS VM (CloudLens Manager Server)
resource "oci_core_instance" "clms_vm" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = "CLMS-VM"
  shape               = "VM.Standard.E4.Flex"

  shape_config {
    ocpus         = 16  # 16 vCPUs 
    memory_in_gbs = 64  # 64 GB RAM
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.brinek_public_subnet.id
    display_name     = "CLMSVNIC"
    assign_public_ip = true
    hostname_label   = "clms"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_images.images[0].id
    boot_volume_size_in_gbs = 200  # 200 GB disk space
  }


  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data = base64encode(<<-EOF
      #!/bin/bash
      useradd -m -s /bin/bash brine
      usermod -aG sudo brine
      mkdir -p /home/brine/.ssh
      echo "${file(var.ssh_public_key_path)}" >> /home/brine/.ssh/authorized_keys
      chown -R brine:brine /home/brine/.ssh
      chmod 700 /home/brine/.ssh
      chmod 600 /home/brine/.ssh/authorized_keys

      echo "brine ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/brine
    EOF
    )
  }

  freeform_tags = {
    "Name" = "CLMS-VM"
    "Role" = "CloudLens-Manager"
    "Env"  = "prod"
    "OS"   = "Ubuntu"
  }
}

# Windows VMs
resource "oci_core_instance" "windows_vm" {
  count               = var.windows_vm_count
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[count.index % length(data.oci_identity_availability_domains.ads.availability_domains)].name
  compartment_id      = var.compartment_ocid
  display_name        = "WindowsVM-${count.index}"
  shape               = "VM.Standard.E4.Flex"

  shape_config {
    ocpus         = 4
    memory_in_gbs = 16
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.brinek_public_subnet.id
    display_name     = "WindowsVNIC-${count.index}"
    assign_public_ip = true
    hostname_label   = "windows-${count.index}"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.windows_images.images[0].id
    boot_volume_size_in_gbs = 100
  }

  metadata = {
    user_data = base64encode(<<-EOF
      <powershell>
      # Set administrator password
      $Password = ConvertTo-SecureString "${var.windows_admin_password}" -AsPlainText -Force
      Set-LocalUser -Name "Administrator" -Password $Password
      
      # Create brine user
      New-LocalUser -Name "brine" -Password $Password -FullName "Brine User" -Description "Admin User"
      Add-LocalGroupMember -Group "Administrators" -Member "brine"
      
      # Enable RDP
      Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
      Get-NetFirewallRule -DisplayGroup "Remote Desktop" | Enable-NetFirewallRule
      Set-Service -Name TermService -StartupType Automatic
      Start-Service TermService
      
      # Configure WinRM for Ansible
      winrm quickconfig -q
      winrm set winrm/config/service/auth '@{Basic="true"}'
      winrm set winrm/config/service '@{AllowUnencrypted="true"}'
      winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
      
      # Set network profile to private
      Set-NetConnectionProfile -InterfaceAlias "Ethernet*" -NetworkCategory Private
      
      # Configure firewall for WinRM
      New-NetFirewallRule -DisplayName "Allow WinRM HTTP" -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow
      New-NetFirewallRule -DisplayName "Allow WinRM HTTPS" -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow
      </powershell>
    EOF
    )
  }

  freeform_tags = {
    "Name" = "WindowsVM-${count.index}"
    "Env"  = "prod"
    "OS"   = "Windows"
  }
}

# Outputs
output "ubuntu_public_ips" {
  value = [for instance in oci_core_instance.ubuntu_vm : instance.public_ip]
}

output "oracle_linux_public_ips" {
  value = [for instance in oci_core_instance.ol_vm : instance.public_ip]
}

output "windows_public_ips" {
  value = [for instance in oci_core_instance.windows_vm : instance.public_ip]
}

output "clms_vm_public_ip" {
  description = "Public IP address of the CLMS VM"
  value       = oci_core_instance.clms_vm.public_ip
}

output "ssh_instructions_to_ubuntu" {
  value = [for instance in oci_core_instance.ubuntu_vm : "ssh -i /Users/brinketu/Downloads/brinendamketum@gmail.com-2025-06-29T13_25_39.809Z.pem brine@${instance.public_ip}"]
}

output "ssh_instructions_to_oracle_linux" {
  value = [for instance in oci_core_instance.ol_vm : "ssh -i /Users/brinketu/Downloads/brinendamketum@gmail.com-2025-06-29T13_25_39.809Z.pem brine@${instance.public_ip}"]
}

output "ssh_instructions_clms" {
  description = "SSH command for CLMS VM"
  value       = "ssh -i /Users/brinketu/Downloads/brinendamketum@gmail.com-2025-06-29T13_25_39.809Z.pem brine@${oci_core_instance.clms_vm.public_ip}"
}

output "rdp_instructions_to_windows" {
  value = [for instance in oci_core_instance.windows_vm : "mstsc /v:${instance.public_ip}"]
}

output "ansible_inventory" {
  value = join("\n", concat(
    ["[ubuntu_vms]"],
    [for i, instance in oci_core_instance.ubuntu_vm : "ubuntu${i + 1} ansible_host=${instance.public_ip} ansible_user=brine"],

    ["", "[oracle_linux_vms]"],
    [for i, instance in oci_core_instance.ol_vm : "ol${i + 1} ansible_host=${instance.public_ip} ansible_user=brine"],

    ["", "[clms]"],
    ["clms ansible_host=${oci_core_instance.clms_vm.public_ip} ansible_user=brine"],

    ["", "[windows]"],
    [for instance in oci_core_instance.windows_vm : instance.public_ip],

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
      "ansible_ssh_private_key_file=/Users/brinketu/Downloads/brinendamketum@gmail.com-2025-06-29T13_25_39.809Z.pem",
      "ansible_ssh_common_args='-o StrictHostKeyChecking=no'"
    ],

    ["", "[oracle_linux_vms:vars]"],
    [
      "ansible_ssh_private_key_file=/Users/brinketu/Downloads/brinendamketum@gmail.com-2025-06-29T13_25_39.809Z.pem",
      "ansible_ssh_common_args='-o StrictHostKeyChecking=no'"
    ],

    ["", "[clms:vars]"],
    [
      "ansible_ssh_private_key_file=/Users/brinketu/Downloads/brinendamketum@gmail.com-2025-06-29T13_25_39.809Z.pem",
      "ansible_ssh_common_args='-o StrictHostKeyChecking=no'"
    ]
  ))
}