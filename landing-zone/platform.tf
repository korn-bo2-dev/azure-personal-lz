resource "azurerm_resource_group" "platform" {
  name     = "rg-platform"
  location = var.location
  tags     = local.tags
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-personal-${var.name_suffix}"
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 0.5 # hard cap on ingestion cost
  tags                = local.tags
}

# Send subscription activity log to Log Analytics (free for activity logs).
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "activity-to-law"
  target_resource_id         = "/subscriptions/${var.subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  dynamic "enabled_log" {
    for_each = ["Administrative", "Security", "Policy", "Alert"]
    content {
      category = enabled_log.value
    }
  }
}
