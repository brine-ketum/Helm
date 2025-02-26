terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.2"
    }
  }
}

# Store username and password before deployment. Same password will be used for ssh base auth
# export TF_VAR_admin_username="brine"  
# export TF_VAR_admin_password="password"
 