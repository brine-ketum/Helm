# Terraform Azure Load Balancer Deployment

​<light>This repository contains Terraform code to deploy a multi-tier infrastructure on Azure.</light>​ The code provisions Virtual Networks, Subnets, a Gateway Load Balancer (GWLB), a Platform Load Balancer (PLB), and VMs, including a web workload running on Ubuntu and a vPacketStack appliance for traffic monitoring.

## Key Components

- Gateway Load Balancer (GWLB)
- Platform Load Balancer (PLB)
- Virtual Networks and Subnets
- Ubuntu VM for web workload
- vPacketStack VM appliance for traffic monitoring

## Code Breakdown

- **main.tf**: Core infrastructure components like VNet, Subnets, and Resource Groups.
- **gwlb.tf**: Configuration for the Gateway Load Balancer.
- **plb.tf**: Configuration for the Platform Load Balancer.
- **ubuntu_wkload.tf**: Deployment of Ubuntu VM for the web workload.
- **vpb.tf**: Deployment of vPacketStack vm (8vCPU, 32GB RAM, 200GB), which includes multiple network interfaces.
- **output.tf**: Defines outputs like public IP addresses of the VMs and Load Balancers.
- **variables.tf**: Variable declarations for customizable deployment.
- **terraform.tfvars**: Contains the values of variables used in the deployment.

## Prerequisites

1. **Terraform v1.0.0+** installed on your machine. [Install Terraform](https://www.terraform.io/downloads)
2. **Azure CLI** installed and authenticated. [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
3. An **Azure Subscription** with the required permissions to create resources such as VMs, load balancers, and networking components.

## Deployment Steps

### 1. Clone the Repository

Clone this repository to your local machine:

```bash
git clone <repository-url>
cd <repository-folder>
```

### 2. Authenticate to Azure

Ensure that you are logged into Azure via CLI:

```az login```

### 3. Modify the Terraform Variables

Before deployment, modify the `terraform.tfvars` file to suit your environment. You can adjust parameters such as the subscription ID, resource group name, location, and VM settings.

For example, in `terraform.tfvars`:

```
subscription_id          = "your-subscription-id"
resource_group_name      = "your-resource-group"
location                 = "East US"
```

Other parameters such as VM size, network configurations, and admin credentials can also be modified as per your requirements.

### 4. Initialize Terraform

Run the following command to initialize Terraform and download necessary providers:

```terraform init```

### 5. Plan the Deployment

Before applying the deployment, you can review the plan to see what resources will be created:

```terraform plan```

### 6. Apply the Deployment

Once satisfied with the plan, apply the configuration to deploy the resources:

```terraform apply```

You will be prompted to confirm the changes. Type `yes` to proceed with the deployment.

### 7. View Output Values

After the deployment is complete, view the output values:

```terraform output```

### 8. Clean Up Resources

To destroy the resources created by Terraform and clean up the Azure environment, run:

```terraform destroy```

## Important Notes

- Ensure that the appropriate Azure Subscription ID is set in the `terraform.tfvars` file.
- The provided admin username and password in the `terraform.tfvars` file will be used for SSH-based authentication to the VMs.
- The infrastructure includes public IP addresses, so ensure that you have proper security measures like firewalls and access control in place.
