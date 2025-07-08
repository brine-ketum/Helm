#!/bin/bash

# Backend storage configuration
TFSTATE_RG="terraform-state-rg"
TFSTATE_STORAGE="tfstatekeysight"  # Must be globally unique - update if taken
TFSTATE_CONTAINER="tfstate"
LOCATION="westus2"

echo "Creating Terraform backend storage..."

# Create resource group
echo "Creating resource group: $TFSTATE_RG"
az group create --name $TFSTATE_RG --location $LOCATION

# Create storage account
echo "Creating storage account: $TFSTATE_STORAGE"
az storage account create \
  --name $TFSTATE_STORAGE \
  --resource-group $TFSTATE_RG \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $TFSTATE_RG \
  --account-name $TFSTATE_STORAGE \
  --query '[0].value' -o tsv)

# Create container
echo "Creating storage container: $TFSTATE_CONTAINER"
az storage container create \
  --name $TFSTATE_CONTAINER \
  --account-name $TFSTATE_STORAGE \
  --account-key $ACCOUNT_KEY

echo "Backend storage setup complete!"
echo "Storage Account: $TFSTATE_STORAGE"
echo "Container: $TFSTATE_CONTAINER"
