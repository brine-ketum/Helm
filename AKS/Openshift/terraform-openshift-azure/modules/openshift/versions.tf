terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.85"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.3"
    }
  }
}
