output "management_group_ids" {
  value = module.alz.management_group_resource_ids
}

output "log_analytics_workspace_id" {
  value = module.management.resource_id
}
