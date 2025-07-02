# environments/prod/terraform.tfvars.example
# Copy this file to terraform.tfvars and update with your values

# Project Configuration
project_id = "poc-project-463913"
region     = "us-east1"
name_prefix = "brinek"

# VM Counts
ubuntu_vm_count  = 1
rhel_vm_count    = 1
windows_vm_count = 0

# SSH Configuration
ssh_username         = "brinendamketum"
ssh_public_key_path  = "/Users/brinketu/Downloads/ssh_key.pub"
ssh_private_key_path = "/Users/brinketu/Downloads/brinendamketum@gmail.com-2025-06-29T13_25_39.809Z.pem"

# Network Security
allowed_ssh_ips   = ["40.143.44.44/32"]  # Replace with your IP
allowed_rdp_ips   = ["40.143.44.44/32"]  # Replace with your IP
allowed_winrm_ips = ["40.143.44.44/32"]  # Replace with your IP

# Optional Features
create_nat_gateway = false
enable_flow_logs   = false

# Windows Credentials (change these!)
windows_admin_username = "brine"
windows_admin_password = "Bravedemo123."  # Use a secure password

# Tags and Labels
additional_tags = []
additional_labels = {
  cost-center = "engineering"
  project     = "poc"
}