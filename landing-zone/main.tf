data "azapi_client_config" "current" {}

locals {
  management_resource_group_name = "rg-management-${var.location}"
  log_analytics_workspace_name   = "law-management-${var.location}"
  ama_identity_name              = "uami-ama"

  # Assignments that would deploy paid features or need a hub network we don't have yet.
  # Flip them back to "Default" when you turn those features on.
  defender_enforcement = var.defender_plans_enabled ? "Default" : "DoNotEnforce"
}

# ---------------------------------------------------------------------------
# Management: Log Analytics, data collection rules and the AMA identity,
# all in the platform subscription.
# ---------------------------------------------------------------------------

module "management" {
  source  = "Azure/avm-ptn-alz-management/azurerm"
  version = "0.9.0"

  location                                  = var.location
  resource_group_name                       = local.management_resource_group_name
  log_analytics_workspace_name              = local.log_analytics_workspace_name
  log_analytics_workspace_daily_quota_gb    = var.log_analytics_daily_quota_gb
  log_analytics_workspace_retention_in_days = 30
  automation_account_name                   = "aa-management-${var.location}"
  enable_telemetry                          = false

  user_assigned_managed_identities = {
    ama = {
      name = local.ama_identity_name
    }
  }
}

# ---------------------------------------------------------------------------
# ALZ: management group hierarchy, policy definitions/assignments and the
# role assignments the policies need.
#
#   Tenant Root
#   └── alz (Azure Landing Zones)
#       ├── platform ── management (platform sub), connectivity, identity, security
#       ├── landingzones ── corp (prod + dev subs), online, local
#       ├── sandbox
#       └── decommissioned
# ---------------------------------------------------------------------------

module "alz" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = "0.22.0"

  architecture_name  = "alz"
  location           = var.location
  parent_resource_id = data.azapi_client_config.current.tenant_id
  enable_telemetry   = false

  subscription_placement = {
    platform = {
      subscription_id       = var.platform_subscription_id
      management_group_name = "management"
    }
    prod = {
      subscription_id       = var.prod_subscription_id
      management_group_name = "corp"
    }
    dev = {
      subscription_id       = var.dev_subscription_id
      management_group_name = "corp"
    }
  }

  # Don't create policy assignments until the management resources they point at exist.
  policy_assignments_dependencies = [
    module.management.data_collection_rule_ids,
    module.management.resource_id,
    module.management.user_assigned_identity_ids,
  ]

  policy_default_values = {
    log_analytics_workspace_id                  = jsonencode({ value = provider::azapi::resource_group_resource_id(var.platform_subscription_id, local.management_resource_group_name, "Microsoft.OperationalInsights/workspaces", [local.log_analytics_workspace_name]) })
    ama_change_tracking_data_collection_rule_id = jsonencode({ value = provider::azapi::resource_group_resource_id(var.platform_subscription_id, local.management_resource_group_name, "Microsoft.Insights/dataCollectionRules", ["dcr-change-tracking"]) })
    ama_mdfc_sql_data_collection_rule_id        = jsonencode({ value = provider::azapi::resource_group_resource_id(var.platform_subscription_id, local.management_resource_group_name, "Microsoft.Insights/dataCollectionRules", ["dcr-defender-sql"]) })
    ama_vm_insights_data_collection_rule_id     = jsonencode({ value = provider::azapi::resource_group_resource_id(var.platform_subscription_id, local.management_resource_group_name, "Microsoft.Insights/dataCollectionRules", ["dcr-vm-insights"]) })
    ama_user_assigned_managed_identity_id       = jsonencode({ value = provider::azapi::resource_group_resource_id(var.platform_subscription_id, local.management_resource_group_name, "Microsoft.ManagedIdentity/userAssignedIdentities", [local.ama_identity_name]) })
    ama_user_assigned_managed_identity_name     = jsonencode({ value = local.ama_identity_name })
    email_security_contact                      = jsonencode({ value = var.security_contact_email })
    resource_group_location                     = jsonencode({ value = var.location })
  }

  policy_assignments_to_modify = {
    alz = {
      policy_assignments = {
        # Paid Defender for Cloud plans.
        Deploy-MDFC-Config-H224 = { enforcement_mode = local.defender_enforcement }
        Deploy-MDFC-OssDb       = { enforcement_mode = local.defender_enforcement }
        Deploy-MDFC-SqlAtp      = { enforcement_mode = local.defender_enforcement }
        Deploy-MDEndpoints      = { enforcement_mode = local.defender_enforcement }
        Deploy-MDEndpointsAMA   = { enforcement_mode = local.defender_enforcement }
      }
    }
    connectivity = {
      policy_assignments = {
        # No DDoS protection plan (about US$3,000/month).
        Enable-DDoS-VNET = { enforcement_mode = "DoNotEnforce" }
      }
    }
    landingzones = {
      policy_assignments = {
        Enable-DDoS-VNET = { enforcement_mode = "DoNotEnforce" }
      }
    }
    corp = {
      policy_assignments = {
        # Needs private DNS zones in a connectivity hub, which isn't deployed yet.
        Deploy-Private-DNS-Zones = { enforcement_mode = "DoNotEnforce" }
      }
    }
  }
}
