# Organization Outputs
output "organization_id" {
  description = "AWS Organization ID"
  value       = local.organization_id
}

output "root_id" {
  description = "Root organizational unit ID"
  value       = local.root_id
}

# Organizational Unit Outputs
output "organizational_units" {
  description = "Map of organizational unit IDs"
  value = {
    root_level   = { for key, value in aws_organizations_organizational_unit.root_level : key => value.id }
    second_level = { for key, value in aws_organizations_organizational_unit.second_level : key => value.id }
  }
}

output "organizational_units_flat" {
  description = "Flat map of all organizational unit IDs"
  value       = local.all_ou_ids
}

# Account Outputs
output "accounts" {
  description = "Map of AWS account IDs"
  value       = { for key, value in aws_organizations_account.accounts : key => value.id }
}

output "log_archive_account_id" {
  description = "Log Archive account ID (for CloudTrail)"
  value       = try(aws_organizations_account.accounts["log_archive"].id, null)
}

output "audit_account_id" {
  description = "Audit account ID (for Config and compliance)"
  value       = try(aws_organizations_account.accounts["audit"].id, null)
}

output "shared_services_account_id" {
  description = "Shared Services account ID"
  value       = try(aws_organizations_account.accounts["shared_services"].id, null)
}

output "aft_tooling_account_id" {
  description = "AFT Tooling account ID"
  value       = try(aws_organizations_account.accounts["aft_tooling"].id, "Not created")
}

# SCP Outputs
output "service_control_policies" {
  description = "Map of Service Control Policies"
  value = {
    for key, policy in aws_organizations_policy.scp :
    key => policy.id
  }
}

# Delegated Administrator Outputs
output "delegated_administrators" {
  description = "Service principals with delegated administration"
  value = {
    for key, admin in aws_organizations_delegated_administrator.service_admin :
    key => admin.service_principal
  }
}
