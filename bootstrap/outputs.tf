output "backend_config" {
  description = "Values for the landing-zone backend."
  value = {
    resource_group_name  = azurerm_resource_group.tfstate.name
    storage_account_name = azurerm_storage_account.tfstate.name
    container_name       = azurerm_storage_container.tfstate.name
  }
}

output "cicd_client_id" {
  description = "Client ID for the pipeline (AZURE_CLIENT_ID)."
  value       = azurerm_user_assigned_identity.cicd.client_id
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}
