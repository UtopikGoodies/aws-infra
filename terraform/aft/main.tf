data "aws_caller_identity" "current" {}

locals {
  account_requests_path = "${path.module}/account-requests"
}

# AFT account requests are managed through the AFT pipeline
# This Terraform workspace validates the structure and can be extended
# to manage account requests programmatically if needed.

# Placeholder for AFT account request management
# Account requests are typically JSON files in account-requests/*/request.auto.tfvars.json
# and are processed by the AWS AFT service pipeline

output "account_requests_path" {
  description = "Path to account requests directory"
  value       = local.account_requests_path
}

output "management_account_id" {
  description = "Management account ID"
  value       = data.aws_caller_identity.current.account_id
}
