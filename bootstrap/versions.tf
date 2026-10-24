terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Bootstrap keeps local state on purpose: it creates the remote backend
  # everything else uses. Keep terraform.tfstate somewhere safe (or migrate
  # it into the container it creates once that exists).
}

provider "azurerm" {
  subscription_id     = var.subscription_id
  storage_use_azuread = true
  features {}
}
