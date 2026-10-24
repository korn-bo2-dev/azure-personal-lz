# Lets the GitHub Actions identity from bootstrap manage everything under the
# ALZ root once your first local apply has created it.
data "azurerm_user_assigned_identity" "cicd" {
  name                = var.cicd_identity_name
  resource_group_name = "rg-tfstate"
}

resource "azurerm_role_assignment" "cicd_alz_owner" {
  scope                = "/providers/Microsoft.Management/managementGroups/alz"
  role_definition_name = "Owner"
  principal_id         = data.azurerm_user_assigned_identity.cicd.principal_id

  depends_on = [module.alz]
}
