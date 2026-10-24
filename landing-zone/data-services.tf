# ---------------------------------------------------------------------------
# Storage account
# ---------------------------------------------------------------------------

resource "azurerm_storage_account" "data" {
  name                            = "stdata${var.name_suffix}"
  resource_group_name             = azurerm_resource_group.workload.name
  location                        = azurerm_resource_group.workload.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = local.tags
}

resource "azurerm_role_assignment" "me_storage" {
  scope                = azurerm_storage_account.data.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.sql_admin_object_id
}

resource "azurerm_role_assignment" "vm_storage" {
  scope                = azurerm_storage_account.data.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_virtual_machine.main.identity[0].principal_id
}

# ---------------------------------------------------------------------------
# Key Vault (RBAC mode)
# ---------------------------------------------------------------------------

resource "azurerm_key_vault" "main" {
  name                       = "kv-personal-${var.name_suffix}"
  resource_group_name        = azurerm_resource_group.workload.name
  location                   = azurerm_resource_group.workload.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  enable_rbac_authorization  = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # personal sandbox: allow clean teardown
  tags                       = local.tags
}

resource "azurerm_role_assignment" "me_kv" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.sql_admin_object_id
}

resource "azurerm_role_assignment" "vm_kv" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_virtual_machine.main.identity[0].principal_id
}

# ---------------------------------------------------------------------------
# Azure SQL Database, free offer (100k vCore-seconds + 32 GB per month)
# Entra ID-only auth: no SQL passwords exist anywhere.
# ---------------------------------------------------------------------------

resource "azurerm_mssql_server" "main" {
  name                = "sql-personal-${var.name_suffix}"
  resource_group_name = azurerm_resource_group.workload.name
  location            = azurerm_resource_group.workload.location
  version             = "12.0"
  minimum_tls_version = "1.2"
  tags                = local.tags

  azuread_administrator {
    login_username              = var.sql_admin_login
    object_id                   = var.sql_admin_object_id
    azuread_authentication_only = true
  }
}

resource "azurerm_mssql_virtual_network_rule" "vm" {
  name      = "allow-snet-vm"
  server_id = azurerm_mssql_server.main.id
  subnet_id = azurerm_subnet.vm.id
}

resource "azurerm_mssql_firewall_rule" "clients" {
  for_each = toset(var.allowed_client_ips)

  name             = "client-${replace(each.value, ".", "-")}"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = each.value
  end_ip_address   = each.value
}

# azapi is used because the free-offer flags are not exposed by azurerm.
resource "azapi_resource" "sqldb_free" {
  type      = "Microsoft.Sql/servers/databases@2023-08-01"
  name      = "sqldb-personal"
  parent_id = azurerm_mssql_server.main.id
  location  = var.location
  tags      = local.tags

  body = {
    sku = {
      name     = "GP_S_Gen5"
      tier     = "GeneralPurpose"
      family   = "Gen5"
      capacity = 2
    }
    properties = {
      useFreeLimit                     = true
      freeLimitExhaustionBehavior      = "AutoPause" # never bills; pauses until next month
      autoPauseDelay                   = 60
      minCapacity                      = 0.5
      maxSizeBytes                     = 34359738368 # 32 GB
      zoneRedundant                    = false
      requestedBackupStorageRedundancy = "Local"
    }
  }
}
