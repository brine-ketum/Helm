terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatekeysight"  # Must be globally unique
    container_name       = "tfstate"
    key                  = "prod/openshift/terraform.tfstate"
  }
}
