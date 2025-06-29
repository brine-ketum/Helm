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

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "/Users/brinketu/Downloads/ssh_key.pub"
}

variable "vpb_installer_path" {
  description = "Path to VPB installer script"
  type        = string
  default     = "/Users/brinketu/Downloads/vpb-3.10.0-18-install-package.sh"
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

# Get latest Ubuntu images
data "oci_core_images" "ubuntu_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.E4.Flex"
  sort_by                  = "TIMECREATED"
  sort_order              = "DESC"
}

# VCN (Virtual Cloud Network) - equivalent to Azure VNet
resource "oci_core_vcn" "vtap_vcn" {
  compartment_id = var.compartment_ocid
  display_name   = "Vtap-VCN"
  cidr_blocks    = ["172.16.0.0/16"]
  dns_label      = "vtapvcn"
}

# Internet Gateway
resource "oci_core_internet_gateway" "vtap_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vtap_vcn.id
  display_name   = "VtapIGW"
}

# NAT Gateway (equivalent to Azure NAT Gateway)
resource "oci_core_nat_gateway" "vtap_nat_gateway" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vtap_vcn.id
  display_name   = "VtapNATGateway"
}

# Route Tables
resource "oci_core_route_table" "public_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vtap_vcn.id
  display_name   = "PublicRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.vtap_igw.id
  }
}

resource "oci_core_route_table" "private_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vtap_vcn.id
  display_name   = "PrivateRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.vtap_nat_gateway.id
  }
}

# Security Lists (equivalent to Azure NSG)
resource "oci_core_security_list" "public_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vtap_vcn.id
  display_name   = "PublicSecurityList"

  # Egress rules - allow all outbound
  egress_security_rules {
    destination      = "0.0.0.0/0"
    protocol         = "all"
    description      = "Allow all outbound traffic"
  }

  # SSH access
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "SSH access"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP access
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "HTTP access"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # Load balancer NAT rules
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "SSH NAT for WebServer1 Source"
    tcp_options {
      min = 60001
      max = 60001
    }
  }

  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "SSH NAT for WebServer1 Destination"
    tcp_options {
      min = 60002
      max = 60002
    }
  }
}

resource "oci_core_security_list" "vpb_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vtap_vcn.id
  display_name   = "VPBSecurityList"

  # Egress rules - allow all outbound
  egress_security_rules {
    destination      = "0.0.0.0/0"
    protocol         = "all"
    description      = "Allow all outbound traffic"
  }

  # Allow all inbound
  ingress_security_rules {
    protocol    = "all"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "Allow all inbound for VPB"
  }

  # VXLAN traffic
  ingress_security_rules {
    protocol    = "17" # UDP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "VXLAN traffic"
    udp_options {
      min = 4789
      max = 4789
    }
  }
}

# Subnets
resource "oci_core_subnet" "source_subnet" {
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.vtap_vcn.id
  display_name        = "SourceSubnet"
  cidr_block          = "172.16.3.0/24"
  dns_label           = "source"
  security_list_ids   = [oci_core_security_list.public_security_list.id]
  route_table_id      = oci_core_route_table.private_route_table.id
  dhcp_options_id     = oci_core_vcn.vtap_vcn.default_dhcp_options_id
}

resource "oci_core_subnet" "destination_subnet" {
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.vtap_vcn.id
  display_name        = "DestinationSubnet"
  cidr_block          = "172.16.4.0/24"
  dns_label           = "destsubnet"
  security_list_ids   = [oci_core_security_list.public_security_list.id]
  route_table_id      = oci_core_route_table.private_route_table.id
  dhcp_options_id     = oci_core_vcn.vtap_vcn.default_dhcp_options_id
}

resource "oci_core_subnet" "consumer_subnet" {
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.vtap_vcn.id
  display_name        = "ConsumerBackendNet"
  cidr_block          = "172.16.10.0/24"
  dns_label           = "consumer"
  security_list_ids   = [oci_core_security_list.public_security_list.id]
  route_table_id      = oci_core_route_table.public_route_table.id
  dhcp_options_id     = oci_core_vcn.vtap_vcn.default_dhcp_options_id
}

resource "oci_core_subnet" "vpb_mgmt_subnet" {
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.vtap_vcn.id
  display_name        = "VPBManagement"
  cidr_block          = "172.16.20.0/24"
  dns_label           = "vpbmgmt"
  security_list_ids   = [oci_core_security_list.vpb_security_list.id]
  route_table_id      = oci_core_route_table.public_route_table.id
  dhcp_options_id     = oci_core_vcn.vtap_vcn.default_dhcp_options_id
}

resource "oci_core_subnet" "vpb_ingress_subnet" {
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.vtap_vcn.id
  display_name        = "VPBIngress"
  cidr_block          = "172.16.21.0/24"
  dns_label           = "vpbingress"
  security_list_ids   = [oci_core_security_list.vpb_security_list.id]
  route_table_id      = oci_core_route_table.private_route_table.id
  dhcp_options_id     = oci_core_vcn.vtap_vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_subnet" "vpb_egress_subnet" {
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.vtap_vcn.id
  display_name        = "VPBEgress"
  cidr_block          = "172.16.22.0/24"
  dns_label           = "vpbegress"
  security_list_ids   = [oci_core_security_list.vpb_security_list.id]
  route_table_id      = oci_core_route_table.private_route_table.id
  dhcp_options_id     = oci_core_vcn.vtap_vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_subnet" "tool_subnet" {
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.vtap_vcn.id
  display_name        = "Tool"
  cidr_block          = "172.16.23.0/24"
  dns_label           = "tool"
  security_list_ids   = [oci_core_security_list.public_security_list.id]
  route_table_id      = oci_core_route_table.public_route_table.id
  dhcp_options_id     = oci_core_vcn.vtap_vcn.default_dhcp_options_id
}

# Public IPs
resource "oci_core_public_ip" "lb_public_ip" {
  compartment_id = var.compartment_ocid
  display_name   = "LoadBalancerPublicIP"
  lifetime       = "RESERVED"
}

resource "oci_core_public_ip" "suricata_public_ip" {
  compartment_id = var.compartment_ocid
  display_name   = "SuricataPublicIP"
  lifetime       = "RESERVED"
}

resource "oci_core_public_ip" "vpb_public_ip" {
  compartment_id = var.compartment_ocid
  display_name   = "VPBPublicIP"
  lifetime       = "RESERVED"
}

# Load Balancer (Network Load Balancer for better performance) - Remove reserved IP for private LB
resource "oci_network_load_balancer_network_load_balancer" "lb" {
  compartment_id = var.compartment_ocid
  display_name   = "VtapLoadBalancer"
  subnet_id      = oci_core_subnet.consumer_subnet.id
  
  is_preserve_source_destination = false

  freeform_tags = {
    "Environment" = "Production"
  }
}

# Load Balancer Backend Set
resource "oci_network_load_balancer_backend_set" "lb_backend_set" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.lb.id
  name                     = "WebServerBackendSet"
  policy                   = "FIVE_TUPLE"
  
  health_checker {
    protocol = "TCP"
    port     = 80
  }
}

# Load Balancer Listener for HTTP
resource "oci_network_load_balancer_listener" "lb_listener_http" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.lb.id
  name                     = "HTTPListener"
  default_backend_set_name = oci_network_load_balancer_backend_set.lb_backend_set.name
  port                     = 80
  protocol                 = "TCP"
}

# Load Balancer Listeners for SSH NAT (equivalent to Azure NAT rules)
resource "oci_network_load_balancer_listener" "lb_listener_ssh_source" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.lb.id
  name                     = "SSHSourceListener"
  default_backend_set_name = oci_network_load_balancer_backend_set.lb_backend_set.name
  port                     = 60001
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_listener" "lb_listener_ssh_dest" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.lb.id
  name                     = "SSHDestListener"
  default_backend_set_name = oci_network_load_balancer_backend_set.lb_backend_set.name
  port                     = 60002
  protocol                 = "TCP"
}

# Use smaller VM shapes to avoid resource limits
# WebServer1 VM with dual NICs
resource "oci_core_instance" "web_server1" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = "WebServer1"
  shape               = "VM.Standard.E3.Flex"

  shape_config {
    ocpus         = 2
    memory_in_gbs = 8
  }

  # Primary VNIC in source subnet
  create_vnic_details {
    subnet_id        = oci_core_subnet.source_subnet.id
    display_name     = "WebServer1-Source-VNIC"
    assign_public_ip = false
    hostname_label   = "webserver1-src"
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
      useradd -m -s /bin/bash azureuser
      usermod -aG sudo azureuser
      echo "azureuser:Keysight123456" | chpasswd
      mkdir -p /home/azureuser/.ssh
      echo "${file(var.ssh_public_key_path)}" >> /home/azureuser/.ssh/authorized_keys
      chown -R azureuser:azureuser /home/azureuser/.ssh
      chmod 700 /home/azureuser/.ssh
      chmod 600 /home/azureuser/.ssh/authorized_keys
      
      # Install nginx
      apt-get update
      apt-get install -y nginx curl wget net-tools htop
      
      # Create simple web page
      cat > /var/www/html/index.html << 'HTML'
      <!DOCTYPE html>
      <html>
      <head>
          <title>OCI VTAP WebServer1</title>
      </head>
      <body>
          <h1>Welcome to OCI VTAP WebServer1</h1>
          <p>This server is running on OCI with dual NICs</p>
          <p>Source subnet: 172.16.3.0/24</p>
          <p>Destination subnet: 172.16.4.0/24</p>
      </body>
      </html>
HTML
      
      # Start nginx
      systemctl enable nginx
      systemctl start nginx
    EOF
    )
  }

  freeform_tags = {
    "Name"        = "WebServer1"
    "Environment" = "Production"
    "FastPath"    = "enabled"
  }
}

# Secondary VNIC for WebServer1 in destination subnet
resource "oci_core_vnic_attachment" "web_server1_dest_vnic" {
  instance_id  = oci_core_instance.web_server1.id
  display_name = "WebServer1-Destination-VNIC"

  create_vnic_details {
    subnet_id        = oci_core_subnet.destination_subnet.id
    display_name     = "WebServer1-Destination-VNIC"
    assign_public_ip = false
    hostname_label   = "webserver1-dest"
  }
}

# Add WebServer1 to Load Balancer Backend Set
resource "oci_network_load_balancer_backend" "web_server1_backend" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.lb.id
  backend_set_name         = oci_network_load_balancer_backend_set.lb_backend_set.name
  port                     = 80
  target_id                = oci_core_instance.web_server1.id
}

# Suricata VM in Tool subnet - Use smaller shape
resource "oci_core_instance" "suricata" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = "Suricata"
  shape               = "VM.Standard.E3.Flex"

  shape_config {
    ocpus         = 2
    memory_in_gbs = 8
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.tool_subnet.id
    display_name     = "SuricataVNIC"
    assign_public_ip = true
    hostname_label   = "suricata"
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
      useradd -m -s /bin/bash azureuser
      usermod -aG sudo azureuser
      echo "azureuser:Keysight123456" | chpasswd
      mkdir -p /home/azureuser/.ssh
      echo "${file(var.ssh_public_key_path)}" >> /home/azureuser/.ssh/authorized_keys
      chown -R azureuser:azureuser /home/azureuser/.ssh
      chmod 700 /home/azureuser/.ssh
      chmod 600 /home/azureuser/.ssh/authorized_keys
      
      # Enable IP forwarding
      echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
      sysctl -p
      
      # Install Suricata
      apt-get update
      apt-get install -y suricata
    EOF
    )
  }

  freeform_tags = {
    "Name"        = "Suricata"
    "Environment" = "Production"
    "Role"        = "IDS"
  }
}

# Remove unnecessary public IP pool resources
# Associate Suricata public IP - handled automatically by assign_public_ip = true

# VPB VM with three NICs - Use smaller shape
resource "oci_core_instance" "vpb_vm" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = "vPB"
  shape               = "VM.Standard.E3.Flex"

  shape_config {
    ocpus         = 4
    memory_in_gbs = 16
  }

  # Primary VNIC in management subnet
  create_vnic_details {
    subnet_id        = oci_core_subnet.vpb_mgmt_subnet.id
    display_name     = "VPB-Management-VNIC"
    assign_public_ip = true
    hostname_label   = "vpb-mgmt"
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
      useradd -m -s /bin/bash vpb
      usermod -aG sudo vpb
      echo "vpb:Keysight!123456" | chpasswd
      mkdir -p /home/vpb/.ssh
      echo "${file(var.ssh_public_key_path)}" >> /home/vpb/.ssh/authorized_keys
      chown -R vpb:vpb /home/vpb/.ssh
      chmod 700 /home/vpb/.ssh
      chmod 600 /home/vpb/.ssh/authorized_keys
      
      # Enable IP forwarding
      echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
      sysctl -p
      
      # Update system
      apt-get update
      apt-get upgrade -y
    EOF
    )
  }

  freeform_tags = {
    "Name"        = "vPB"
    "Environment" = "Production"
    "Role"        = "PacketBroker"
  }
}

# Secondary VNIC for VPB Ingress
resource "oci_core_vnic_attachment" "vpb_ingress_vnic" {
  instance_id  = oci_core_instance.vpb_vm.id
  display_name = "VPB-Ingress-VNIC"

  create_vnic_details {
    subnet_id        = oci_core_subnet.vpb_ingress_subnet.id
    display_name     = "VPB-Ingress-VNIC"
    assign_public_ip = false
    hostname_label   = "vpb-ingress"
    skip_source_dest_check = true
  }
}

# Tertiary VNIC for VPB Egress
resource "oci_core_vnic_attachment" "vpb_egress_vnic" {
  instance_id  = oci_core_instance.vpb_vm.id
  display_name = "VPB-Egress-VNIC"

  create_vnic_details {
    subnet_id        = oci_core_subnet.vpb_egress_subnet.id
    display_name     = "VPB-Egress-VNIC"
    assign_public_ip = false
    hostname_label   = "vpb-egress"
    skip_source_dest_check = true
  }
}

# VPB Installation using remote-exec
resource "null_resource" "vpb_install" {
  depends_on = [oci_core_instance.vpb_vm]

  triggers = {
    script_checksum = filesha256("/Users/brinketu/Downloads/vpb-3.10.0-18-install-package.sh")
  }

  # Upload VPB installer
  provisioner "file" {
    source      = var.vpb_installer_path
    destination = "/home/vpb/vpb-installer.sh"

    connection {
      type        = "ssh"
      user        = "vpb"
      private_key = file(var.private_key_path)
      host        = oci_core_instance.vpb_vm.public_ip
      timeout     = "10m"
    }
  }

  # Install VPB
  provisioner "remote-exec" {
    inline = [
      "ls -l /home/vpb",
      "sleep 10",
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
      private_key = file(var.private_key_path)
      host        = oci_core_instance.vpb_vm.public_ip
      timeout     = "45m"
    }
  }
}

# Outputs
output "vpb_public_ip" {
  value = oci_core_instance.vpb_vm.public_ip
}

output "load_balancer_ip" {
  value = oci_network_load_balancer_network_load_balancer.lb.ip_addresses[0].ip_address
}

output "suricata_public_ip" {
  value = oci_core_instance.suricata.public_ip
}

output "webserver1_source_private_ip" {
  value = oci_core_instance.web_server1.private_ip
}

output "webserver1_dest_private_ip" {
  value = data.oci_core_vnic.web_server1_dest_vnic.private_ip_address
}

# Data source to get the destination VNIC details
data "oci_core_vnic" "web_server1_dest_vnic" {
  vnic_id = oci_core_vnic_attachment.web_server1_dest_vnic.vnic_id
}

output "ssh_instructions" {
  value = <<EOF
SSH to WebServer1 via Load Balancer (port 60001): ssh azureuser@${oci_network_load_balancer_network_load_balancer.lb.ip_addresses[0].ip_address} -p 60001 -i ${var.private_key_path}
SSH to Suricata VM: ssh azureuser@${oci_core_instance.suricata.public_ip} -i ${var.private_key_path}
SSH to VPB: ssh vpb@${oci_core_instance.vpb_vm.public_ip} -i ${var.private_key_path}
Load Balancer Web Access: http://${oci_network_load_balancer_network_load_balancer.lb.ip_addresses[0].ip_address}
EOF
}