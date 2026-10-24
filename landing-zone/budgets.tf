locals {
  budget_subscriptions = {
    platform = var.platform_subscription_id
    prod     = var.prod_subscription_id
    dev      = var.dev_subscription_id
  }
}

resource "azurerm_consumption_budget_subscription" "monthly" {
  for_each = local.budget_subscriptions

  name            = "budget-monthly"
  subscription_id = "/subscriptions/${each.value}"
  amount          = var.budget_amounts[each.key]
  time_grain      = "Monthly"

  time_period {
    start_date = "2026-11-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.security_contact_email]
  }

  notification {
    enabled        = true
    threshold      = 90
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.security_contact_email]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = [var.security_contact_email]
  }

  lifecycle {
    ignore_changes = [time_period]
  }
}
