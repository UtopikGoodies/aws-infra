output "landing_zone_id" {
  description = "Control Tower landing zone ID"
  value       = try(aws_controltower_landing_zone.main.id, null)
}

output "landing_zone_arn" {
  description = "Control Tower landing zone ARN"
  value       = try(aws_controltower_landing_zone.main.arn, null)
}

output "organization_id" {
  description = "AWS Organization ID"
  value       = aws_organizations_organization.main.id
}

output "organization_arn" {
  description = "AWS Organization ARN"
  value       = aws_organizations_organization.main.arn
}

output "root_account_id" {
  description = "Management/Root account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "central_logging_bucket" {
  description = "S3 bucket for Control Tower central logging"
  value       = aws_s3_bucket.central_logging.id
}

output "cloudtrail_bucket" {
  description = "S3 bucket for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail_logs.id
}

output "enabled_regions" {
  description = "Regions where Control Tower is enabled"
  value       = var.enabled_regions
}

output "guardrail_level" {
  description = "Control Tower guardrail compliance level"
  value       = var.guardrail_level
}
