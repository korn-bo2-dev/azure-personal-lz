terraform {
  required_version = ">= 1.12, < 2.0"

  required_providers {
    alz = {
      source  = "Azure/alz"
      version = "~> 0.21"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.50"
    }
  }

  # Filled in at init time (see README).
  backend "azurerm" {
    key              = "landing-zone.tfstate"
    use_azuread_auth = true
  }
}

# Platform resources (management, later connectivity) live in the platform subscription.
provider "azurerm" {
  subscription_id     = var.platform_subscription_id
  storage_use_azuread = true
  features {}
}

provider "azapi" {
  subscription_id = var.platform_subscription_id
}

# Azure Landing Zones reference library: management groups, archetypes, policies.
provider "alz" {
  library_references = [{
    path = "platform/alz"
    ref  = "2026.04.2"
  }]
}
