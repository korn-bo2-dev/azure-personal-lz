# ---------------------------------------------------------------------------
# Management group + guardrail policies
# ---------------------------------------------------------------------------

resource "azurerm_management_group" "personal" {
  name         = "mg-personal"
  display_name = "Personal"
}

resource "azurerm_management_group_subscription_association" "personal" {
  management_group_id = azurerm_management_group.personal.id
  subscription_id     = "/subscriptions/${var.subscription_id}"
}

locals {
  # Built-in policy definition IDs
  policy_allowed_locations    = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  policy_allowed_rg_locations = "/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988"
  policy_nic_no_public_ip     = "/providers/Microsoft.Authorization/policyDefinitions/83a86a26-fd1f-447c-b59d-e51f44264114"
}

resource "azurerm_management_group_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  display_name         = "Allowed locations"
  management_group_id  = azurerm_management_group.personal.id
  policy_definition_id = local.policy_allowed_locations

  parameters = jsonencode({
    listOfAllowedLocations = { value = [var.location] }
  })
}

resource "azurerm_management_group_policy_assignment" "allowed_rg_locations" {
  name                 = "allowed-rg-locations"
  display_name         = "Allowed locations for resource groups"
  management_group_id  = azurerm_management_group.personal.id
  policy_definition_id = local.policy_allowed_rg_locations

  parameters = jsonencode({
    listOfAllowedLocations = { value = [var.location] }
  })
}

resource "azurerm_management_group_policy_assignment" "nic_no_public_ip" {
  name                 = "deny-nic-public-ip"
  display_name         = "Network interfaces should not have public IPs"
  management_group_id  = azurerm_management_group.personal.id
  policy_definition_id = local.policy_nic_no_public_ip
}

resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "budget-monthly"
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = var.budget_amount
  time_grain      = "Monthly"

  time_period {
    start_date = "2026-11-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.budget_contact_emails
  }

  notification {
    enabled        = true
    threshold      = 90
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.budget_contact_emails
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = var.budget_contact_emails
  }

  lifecycle {
    ignore_changes = [time_period]
  }
}
