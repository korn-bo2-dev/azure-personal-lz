locals {
  tags = {
    environment = "personal"
    managed-by  = "terraform"
  }

  subnets = {
    vm = cidrsubnet(var.address_space, 8, 1) # 10.10.1.0/24
    pe = cidrsubnet(var.address_space, 8, 2) # 10.10.2.0/24, private endpoints (later)
  }
}

data "azurerm_client_config" "current" {}
