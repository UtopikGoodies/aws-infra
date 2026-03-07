# Root module outputs - aggregated from all child modules

# Bootstrap outputs
output "state_bucket_name" {
  description = "S3 bucket name used for Terraform state"
  value       = module.bootstrap.state_bucket_name
}

output "lock_table_name" {
  description = "DynamoDB table name used for state locking"
  value       = module.bootstrap.lock_table_name
}

output "management_account_id" {
  description = "AWS Management/Root Account ID"
  value       = module.bootstrap.management_account_id
}

# Control Tower outputs
output "organization_id" {
  description = "AWS Organization ID"
  value       = module.control_tower.organization_id
}

output "organization_arn" {
  description = "AWS Organization ARN"
  value       = module.control_tower.organization_arn
}

output "landing_zone_id" {
  description = "Control Tower Landing Zone ID"
  value       = module.control_tower.landing_zone_id
}

output "landing_zone_arn" {
  description = "Control Tower Landing Zone ARN"
  value       = module.control_tower.landing_zone_arn
}

output "central_logging_bucket" {
  description = "S3 bucket used by Control Tower for central logging"
  value       = module.control_tower.central_logging_bucket
}

# Organization outputs
output "organizational_units" {
  description = "All organizational units created (by level)"
  value       = module.org.organizational_units
}

output "organizational_units_flat" {
  description = "Flat map of all organizational unit IDs"
  value       = module.org.organizational_units_flat
}

output "accounts" {
  description = "All AWS accounts created"
  value       = module.org.accounts
}

output "identity_center_instance_arn" {
  description = "IAM Identity Center instance ARN"
  value       = try(module.org.identity_center_instance_arn, null)
}

output "permission_sets" {
  description = "Identity Center permission sets"
  value       = try(module.org.permission_sets, {})
}

# Deployment summary
output "deployment_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    management_account    = module.bootstrap.management_account_id
    organization_id       = module.control_tower.organization_id
    landing_zone_deployed = module.control_tower.landing_zone_id != null
    organizational_units  = length(module.org.organizational_units_flat)
    state_backend         = "s3://${module.bootstrap.state_bucket_name}"
  }
}
