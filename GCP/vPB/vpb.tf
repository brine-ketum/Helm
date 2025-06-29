terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
  required_version = ">=1.0"
}

# Variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "poc-project-463913"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-east1-b"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/gcp-key.pub"
}

variable "vpb_installer_path" {
  description = "Path to VPB installer script"
  type        = string
  default     = "/Users/brinketu/Downloads/vpb-3.10.0-18-install-package.sh"
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/gcp-key"
}

# Provider configuration
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# VPC Network (equivalent to Azure VNet/OCI VCN)
resource "google_compute_network" "vtap_vpc" {
  name                    = "vtap-vpc"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"
}

# Cloud Router for NAT Gateway
resource "google_compute_router" "vtap_router" {
  name    = "vtap-router"
  region  = var.region
  network = google_compute_network.vtap_vpc.id
}

# NAT Gateway (equivalent to Azure/OCI NAT Gateway)
resource "google_compute_router_nat" "vtap_nat" {
  name                               = "vtap-nat-gateway"
  router                            = google_compute_router.vtap_router.name
  region                            = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Subnets
resource "google_compute_subnetwork" "source_subnet" {
  name          = "source-subnet"
  ip_cidr_range = "172.16.3.0/24"
  region        = var.region
  network       = google_compute_network.vtap_vpc.id
  
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "destination_subnet" {
  name          = "destination-subnet"
  ip_cidr_range = "172.16.4.0/24"
  region        = var.region
  network       = google_compute_network.vtap_vpc.id
  
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "consumer_subnet" {
  name          = "consumer-backend-net"
  ip_cidr_range = "172.16.10.0/24"
  region        = var.region
  network       = google_compute_network.vtap_vpc.id
}

resource "google_compute_subnetwork" "vpb_mgmt_subnet" {
  name          = "vpb-management"
  ip_cidr_range = "172.16.20.0/24"
  region        = var.region
  network       = google_compute_network.vtap_vpc.id
}

resource "google_compute_subnetwork" "vpb_ingress_subnet" {
  name          = "vpb-ingress"
  ip_cidr_range = "172.16.21.0/24"
  region        = var.region
  network       = google_compute_network.vtap_vpc.id
}

resource "google_compute_subnetwork" "vpb_egress_subnet" {
  name          = "vpb-egress"
  ip_cidr_range = "172.16.22.0/24"
  region        = var.region
  network       = google_compute_network.vtap_vpc.id
}

resource "google_compute_subnetwork" "tool_subnet" {
  name          = "tool-subnet"
  ip_cidr_range = "172.16.23.0/24"
  region        = var.region
  network       = google_compute_network.vtap_vpc.id
}

# Firewall Rules (equivalent to Azure NSG/OCI Security Lists)
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vtap_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vtap-vm"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vtap_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vtap-vm"]
}

resource "google_compute_firewall" "allow_ssh_nat" {
  name    = "allow-ssh-nat"
  network = google_compute_network.vtap_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["60001", "60002"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vtap-vm"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.vtap_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["172.16.0.0/16"]
  target_tags   = ["vtap-vm"]
}

resource "google_compute_firewall" "allow_vpb_all" {
  name    = "allow-vpb-all"
  network = google_compute_network.vtap_vpc.name

  allow {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vpb-vm"]
}

resource "google_compute_firewall" "allow_vxlan" {
  name    = "allow-vxlan"
  network = google_compute_network.vtap_vpc.name

  allow {
    protocol = "udp"
    ports    = ["4789"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vpb-vm"]
}

# Static IP addresses for Load Balancer and VMs
resource "google_compute_global_address" "lb_public_ip" {
  name = "lb-public-ip"
}

resource "google_compute_address" "suricata_public_ip" {
  name   = "suricata-public-ip"
  region = var.region
}

resource "google_compute_address" "vpb_public_ip" {
  name   = "vpb-public-ip"
  region = var.region
}

# Load Balancer Components
# Backend service for HTTP traffic
resource "google_compute_backend_service" "web_backend" {
  name                  = "web-backend-service"
  port_name             = "http"
  protocol              = "HTTP"
  timeout_sec           = 10
  enable_cdn           = false
  load_balancing_scheme = "EXTERNAL"

  backend {
    group = google_compute_instance_group.web_servers_source.id
  }

  backend {
    group = google_compute_instance_group.web_servers_dest.id
  }

  health_checks = [google_compute_health_check.web_health.id]
}

# Health check for web servers
resource "google_compute_health_check" "web_health" {
  name = "web-health-check"

  tcp_health_check {
    port = "80"
  }

  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

# URL map for load balancer
resource "google_compute_url_map" "web_url_map" {
  name            = "web-url-map"
  default_service = google_compute_backend_service.web_backend.id
}

# HTTP proxy
resource "google_compute_target_http_proxy" "web_proxy" {
  name    = "web-proxy"
  url_map = google_compute_url_map.web_url_map.id
}

# Global forwarding rule for HTTP
resource "google_compute_global_forwarding_rule" "web_forwarding_rule" {
  name       = "web-forwarding-rule"
  target     = google_compute_target_http_proxy.web_proxy.id
  port_range = "80"
  ip_address = google_compute_global_address.lb_public_ip.address
}

# Instance group for source subnet web servers
resource "google_compute_instance_group" "web_servers_source" {
  name = "web-servers-source-group"
  zone = var.zone

  instances = [
    google_compute_instance.web_server1.id,
  ]

  named_port {
    name = "http"
    port = "80"
  }

  named_port {
    name = "ssh"
    port = "22"
  }
}

# Instance group for destination subnet web servers
resource "google_compute_instance_group" "web_servers_dest" {
  name = "web-servers-dest-group"
  zone = var.zone

  instances = [
    google_compute_instance.web_server2.id,
  ]

  named_port {
    name = "http"
    port = "80"
  }

  named_port {
    name = "ssh"
    port = "22"
  }
}

# WebServer1 VM with single network interface (GCP limitation)
resource "google_compute_instance" "web_server1" {
  name         = "webserver1"
  machine_type = "e2-standard-2"
  zone         = var.zone

  tags = ["vtap-vm", "webserver"]

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
      size  = 50
    }
  }

  # Primary network interface (source subnet)
  network_interface {
    subnetwork = google_compute_subnetwork.source_subnet.id
    network_ip = null # Dynamic IP
  }

  metadata = {
    ssh-keys = "azureuser:${file(var.ssh_public_key_path)}"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    apt-get update
    apt-get upgrade -y
    
    # Create azureuser account
    useradd -m -s /bin/bash azureuser
    usermod -aG sudo azureuser
    echo "azureuser:Keysight123456" | chpasswd
    
    # Set up SSH keys for azureuser
    mkdir -p /home/azureuser/.ssh
    echo "${file(var.ssh_public_key_path)}" >> /home/azureuser/.ssh/authorized_keys
    chown -R azureuser:azureuser /home/azureuser/.ssh
    chmod 700 /home/azureuser/.ssh
    chmod 600 /home/azureuser/.ssh/authorized_keys
    
    # Enable IP forwarding
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    sysctl -p
    
    # Install nginx and dependencies
    apt-get install -y nginx curl wget net-tools htop
    
    # Create custom web page
    cat > /var/www/html/index.html << 'HTML'
    <!DOCTYPE html>
    <html>
    <head>
        <title>GCP VTAP WebServer1</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            .container { max-width: 600px; margin: 0 auto; }
            .info { background: #f0f0f0; padding: 20px; border-radius: 5px; margin: 20px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Welcome to GCP VTAP WebServer1</h1>
            <p>This server is running on Google Cloud Platform</p>
            
            <div class="info">
                <h3>Network Configuration:</h3>
                <p><strong>Source subnet:</strong> 172.16.3.0/24</p>
                <p><strong>Load Balancer:</strong> Global HTTP(S) Load Balancer</p>
                <p><strong>SSH NAT:</strong> Ports 60001 and 60002</p>
            </div>
        </div>
    </body>
    </html>
HTML
    
    # Configure and start nginx
    systemctl enable nginx
    systemctl start nginx
    
    # Log completion
    echo "WebServer1 startup completed at $(date)" > /var/log/webserver-startup.log
  EOF

  service_account {
    scopes = ["cloud-platform"]
  }

  can_ip_forward = true

  labels = {
    environment = "production"
    role        = "webserver"
    fastpath    = "enabled"
  }
}

# WebServer2 VM in destination subnet (separate VM to simulate dual-NIC functionality)
resource "google_compute_instance" "web_server2" {
  name         = "webserver2"
  machine_type = "e2-standard-2"
  zone         = var.zone

  tags = ["vtap-vm", "webserver"]

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
      size  = 50
    }
  }

  # Network interface in destination subnet
  network_interface {
    subnetwork = google_compute_subnetwork.destination_subnet.id
    network_ip = null # Dynamic IP
  }

  metadata = {
    ssh-keys = "azureuser:${file(var.ssh_public_key_path)}"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    apt-get update
    apt-get upgrade -y
    
    # Create azureuser account
    useradd -m -s /bin/bash azureuser
    usermod -aG sudo azureuser
    echo "azureuser:Keysight123456" | chpasswd
    
    # Set up SSH keys for azureuser
    mkdir -p /home/azureuser/.ssh
    echo "${file(var.ssh_public_key_path)}" >> /home/azureuser/.ssh/authorized_keys
    chown -R azureuser:azureuser /home/azureuser/.ssh
    chmod 700 /home/azureuser/.ssh
    chmod 600 /home/azureuser/.ssh/authorized_keys
    
    # Enable IP forwarding
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    sysctl -p
    
    # Install nginx and dependencies
    apt-get install -y nginx curl wget net-tools htop
    
    # Create custom web page
    cat > /var/www/html/index.html << 'HTML'
    <!DOCTYPE html>
    <html>
    <head>
        <title>GCP VTAP WebServer2</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            .container { max-width: 600px; margin: 0 auto; }
            .info { background: #f0f0f0; padding: 20px; border-radius: 5px; margin: 20px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Welcome to GCP VTAP WebServer2</h1>
            <p>This server is running on Google Cloud Platform in destination subnet</p>
            
            <div class="info">
                <h3>Network Configuration:</h3>
                <p><strong>Destination subnet:</strong> 172.16.4.0/24</p>
                <p><strong>Load Balancer:</strong> Global HTTP(S) Load Balancer</p>
            </div>
        </div>
    </body>
    </html>
HTML
    
    # Configure and start nginx
    systemctl enable nginx
    systemctl start nginx
    
    # Log completion
    echo "WebServer2 startup completed at $(date)" > /var/log/webserver-startup.log
  EOF

  service_account {
    scopes = ["cloud-platform"]
  }

  can_ip_forward = true

  labels = {
    environment = "production"
    role        = "webserver"
    fastpath    = "enabled"
  }
}

# Suricata VM in Tool subnet
resource "google_compute_instance" "suricata" {
  name         = "suricata"
  machine_type = "n1-standard-4"
  zone         = var.zone

  tags = ["vtap-vm", "suricata"]

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
      size  = 50
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.tool_subnet.id
    access_config {
      nat_ip = google_compute_address.suricata_public_ip.address
    }
  }

  metadata = {
    ssh-keys = "azureuser:${file(var.ssh_public_key_path)}"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    apt-get update
    apt-get upgrade -y
    
    # Create azureuser account
    useradd -m -s /bin/bash azureuser
    usermod -aG sudo azureuser
    echo "azureuser:Keysight123456" | chpasswd
    
    # Set up SSH keys for azureuser
    mkdir -p /home/azureuser/.ssh
    echo "${file(var.ssh_public_key_path)}" >> /home/azureuser/.ssh/authorized_keys
    chown -R azureuser:azureuser /home/azureuser/.ssh
    chmod 700 /home/azureuser/.ssh
    chmod 600 /home/azureuser/.ssh/authorized_keys
    
    # Enable IP forwarding
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    sysctl -p
    
    # Install Suricata and dependencies
    apt-get install -y software-properties-common
    add-apt-repository -y ppa:oisf/suricata-stable
    apt-get update
    apt-get install -y suricata curl wget net-tools htop tcpdump
    
    # Basic Suricata setup
    systemctl enable suricata
    
    # Log completion
    echo "Suricata startup completed at $(date)" > /var/log/suricata-startup.log
  EOF

  service_account {
    scopes = ["cloud-platform"]
  }

  can_ip_forward = true

  labels = {
    environment = "production"
    role        = "ids"
  }
}

# VPB VM with single network interface (GCP limitation workaround)
resource "google_compute_instance" "vpb_vm" {
  name         = "vpb"
  machine_type = "n1-standard-8"
  zone         = var.zone

  tags = ["vpb-vm"]

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
      size  = 50
    }
  }

  # Primary network interface (management)
  network_interface {
    subnetwork = google_compute_subnetwork.vpb_mgmt_subnet.id
    access_config {
      nat_ip = google_compute_address.vpb_public_ip.address
    }
  }

  metadata = {
    ssh-keys = "vpb:${file(var.ssh_public_key_path)}"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    apt-get update
    apt-get upgrade -y
    
    # Create vpb user account
    useradd -m -s /bin/bash vpb
    usermod -aG sudo vpb
    echo "vpb:Keysight!123456" | chpasswd
    
    # Set up SSH keys for vpb user
    mkdir -p /home/vpb/.ssh
    echo "${file(var.ssh_public_key_path)}" >> /home/vpb/.ssh/authorized_keys
    chown -R vpb:vpb /home/vpb/.ssh
    chmod 700 /home/vpb/.ssh
    chmod 600 /home/vpb/.ssh/authorized_keys
    
    # Enable IP forwarding
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    sysctl -p
    
    # Install dependencies
    apt-get install -y curl wget net-tools htop tcpdump
    
    # Log completion
    echo "VPB startup completed at $(date)" > /var/log/vpb-startup.log
  EOF

  service_account {
    scopes = ["cloud-platform"]
  }

  can_ip_forward = true

  labels = {
    environment = "production"
    role        = "packet-broker"
  }
}

# Additional VPB VMs for ingress and egress (to simulate multi-NIC functionality)
resource "google_compute_instance" "vpb_ingress" {
  name         = "vpb-ingress"
  machine_type = "n1-standard-4"
  zone         = var.zone

  tags = ["vpb-vm"]

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
      size  = 30
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpb_ingress_subnet.id
  }

  metadata = {
    ssh-keys = "vpb:${file(var.ssh_public_key_path)}"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y curl wget net-tools htop
    useradd -m -s /bin/bash vpb
    usermod -aG sudo vpb
    echo "vpb:Keysight!123456" | chpasswd
    mkdir -p /home/vpb/.ssh
    echo "${file(var.ssh_public_key_path)}" >> /home/vpb/.ssh/authorized_keys
    chown -R vpb:vpb /home/vpb/.ssh
    chmod 700 /home/vpb/.ssh
    chmod 600 /home/vpb/.ssh/authorized_keys
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    sysctl -p
  EOF

  service_account {
    scopes = ["cloud-platform"]
  }

  can_ip_forward = true

  labels = {
    environment = "production"
    role        = "packet-broker-ingress"
  }
}

resource "google_compute_instance" "vpb_egress" {
  name         = "vpb-egress"
  machine_type = "n1-standard-4"
  zone         = var.zone

  tags = ["vpb-vm"]

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
      size  = 30
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpb_egress_subnet.id
  }

  metadata = {
    ssh-keys = "vpb:${file(var.ssh_public_key_path)}"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y curl wget net-tools htop
    useradd -m -s /bin/bash vpb
    usermod -aG sudo vpb
    echo "vpb:Keysight!123456" | chpasswd
    mkdir -p /home/vpb/.ssh
    echo "${file(var.ssh_public_key_path)}" >> /home/vpb/.ssh/authorized_keys
    chown -R vpb:vpb /home/vpb/.ssh
    chmod 700 /home/vpb/.ssh
    chmod 600 /home/vpb/.ssh/authorized_keys
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    sysctl -p
  EOF

  service_account {
    scopes = ["cloud-platform"]
  }

  can_ip_forward = true

  labels = {
    environment = "production"
    role        = "packet-broker-egress"
  }
}

# VPB Installation using remote-exec
resource "null_resource" "vpb_install" {
  depends_on = [google_compute_instance.vpb_vm]

  triggers = {
    script_checksum = filesha256(var.vpb_installer_path)
    instance_id     = google_compute_instance.vpb_vm.id
  }

  # Upload VPB installer
  provisioner "file" {
    source      = var.vpb_installer_path
    destination = "/home/vpb/vpb-installer.sh"

    connection {
      type        = "ssh"
      user        = "vpb"
      private_key = file(var.ssh_private_key_path)
      host        = google_compute_address.vpb_public_ip.address
      timeout     = "10m"
    }
  }

  # Install VPB
  provisioner "remote-exec" {
    inline = [
      "ls -l /home/vpb",
      "sleep 15",
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
      private_key = file(var.ssh_private_key_path)
      host        = google_compute_address.vpb_public_ip.address
      timeout     = "45m"
    }
  }
}

# TCP Load Balancer for SSH NAT (equivalent to Azure NAT rules)
# Backend service for SSH port 60001 (WebServer1 source)
resource "google_compute_backend_service" "ssh_source_backend" {
  name                  = "ssh-source-backend"
  port_name             = "ssh"
  protocol              = "TCP"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL"

  backend {
    group = google_compute_instance_group.web_servers_source.id
  }

  health_checks = [google_compute_health_check.ssh_health.id]
}

# Backend service for SSH port 60002 (WebServer2 destination)
resource "google_compute_backend_service" "ssh_dest_backend" {
  name                  = "ssh-dest-backend"
  port_name             = "ssh"
  protocol              = "TCP"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL"

  backend {
    group = google_compute_instance_group.web_servers_dest.id
  }

  health_checks = [google_compute_health_check.ssh_health.id]
}

# Health check for SSH
resource "google_compute_health_check" "ssh_health" {
  name = "ssh-health-check"

  tcp_health_check {
    port = "22"
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

# Target TCP proxy for SSH NAT
resource "google_compute_target_tcp_proxy" "ssh_source_proxy" {
  name            = "ssh-source-proxy"
  backend_service = google_compute_backend_service.ssh_source_backend.id
}

resource "google_compute_target_tcp_proxy" "ssh_dest_proxy" {
  name            = "ssh-dest-proxy"
  backend_service = google_compute_backend_service.ssh_dest_backend.id
}

# Global forwarding rules for SSH NAT
resource "google_compute_global_forwarding_rule" "ssh_source_forwarding" {
  name       = "ssh-source-forwarding"
  target     = google_compute_target_tcp_proxy.ssh_source_proxy.id
  port_range = "60001"
  ip_address = google_compute_global_address.lb_public_ip.address
}

resource "google_compute_global_forwarding_rule" "ssh_dest_forwarding" {
  name       = "ssh-dest-forwarding"
  target     = google_compute_target_tcp_proxy.ssh_dest_proxy.id
  port_range = "60002"
  ip_address = google_compute_global_address.lb_public_ip.address
}

# Remove the problematic ssh instance group
# SSH access will be handled through individual instance groups

# Outputs
output "vpb_public_ip" {
  description = "Public IP address of the VPB VM"
  value       = google_compute_address.vpb_public_ip.address
}

output "load_balancer_ip" {
  description = "Public IP address of the Load Balancer"
  value       = google_compute_global_address.lb_public_ip.address
}

output "suricata_public_ip" {
  description = "Public IP address of the Suricata VM"
  value       = google_compute_address.suricata_public_ip.address
}

output "webserver1_source_private_ip" {
  description = "Private IP of WebServer1 source interface"
  value       = google_compute_instance.web_server1.network_interface[0].network_ip
}

output "webserver2_dest_private_ip" {
  description = "Private IP of WebServer2 destination interface"
  value       = google_compute_instance.web_server2.network_interface[0].network_ip
}

output "vpb_mgmt_private_ip" {
  description = "Private IP of VPB management interface"
  value       = google_compute_instance.vpb_vm.network_interface[0].network_ip
}

output "vpb_ingress_private_ip" {
  description = "Private IP of VPB ingress interface"
  value       = google_compute_instance.vpb_ingress.network_interface[0].network_ip
}

output "vpb_egress_private_ip" {
  description = "Private IP of VPB egress interface"
  value       = google_compute_instance.vpb_egress.network_interface[0].network_ip
}

output "ssh_instructions" {
  description = "SSH connection instructions"
  value = <<EOF
SSH to WebServer1 via Load Balancer (port 60001): ssh azureuser@${google_compute_global_address.lb_public_ip.address} -p 60001 -i ${var.ssh_private_key_path}
SSH to WebServer2 via Load Balancer (port 60002): ssh azureuser@${google_compute_global_address.lb_public_ip.address} -p 60002 -i ${var.ssh_private_key_path}
SSH to Suricata VM: ssh azureuser@${google_compute_address.suricata_public_ip.address} -i ${var.ssh_private_key_path}
SSH to VPB Management: ssh vpb@${google_compute_address.vpb_public_ip.address} -i ${var.ssh_private_key_path}
Load Balancer Web Access: http://${google_compute_global_address.lb_public_ip.address}

Note: VPB is distributed across three VMs in GCP:
- VPB Management: ${google_compute_address.vpb_public_ip.address}
- VPB Ingress: ${google_compute_instance.vpb_ingress.network_interface[0].network_ip} (private)
- VPB Egress: ${google_compute_instance.vpb_egress.network_interface[0].network_ip} (private)
EOF
}