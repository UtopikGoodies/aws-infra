# AWS Config Aggregator for organization-wide compliance monitoring
# Centralizes Config data from all member accounts into the management account
# Set enable_config_rules = true to deploy (requires AWS Config setup on all accounts)

resource "aws_config_configuration_aggregator" "organization" {
  count = var.enable_config_rules ? 1 : 0
  name  = "organization-aggregator"

  account_aggregation_source {
    all_regions = true
    account_ids = concat(
      [data.aws_caller_identity.current.account_id],
      [for account in aws_organizations_account.accounts : account.id]
    )
  }

  tags = var.default_tags
}

# Authorization for organizational accounts to report to aggregator
resource "aws_config_organization_managed_rule" "cloudtrail_enabled" {
  count           = var.enable_config_rules ? 1 : 0
  name            = "cloudtrail-enabled"
  rule_identifier = "CLOUD_TRAIL_ENABLED"
}

resource "aws_config_organization_managed_rule" "iam_policy_no_statements_with_admin_access" {
  count           = var.enable_config_rules ? 1 : 0
  name            = "iam-policy-no-admin-access"
  rule_identifier = "IAM_POLICY_NO_STATEMENTS_WITH_ADMIN_ACCESS"
}

resource "aws_config_organization_managed_rule" "root_account_mfa_enabled" {
  count           = var.enable_config_rules ? 1 : 0
  name            = "root-account-mfa-enabled"
  rule_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
}

resource "aws_config_organization_managed_rule" "s3_bucket_public_read_prohibited" {
  count           = var.enable_config_rules ? 1 : 0
  name            = "s3-bucket-public-read-prohibited"
  rule_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
}

resource "aws_config_organization_managed_rule" "s3_bucket_public_write_prohibited" {
  count           = var.enable_config_rules ? 1 : 0
  name            = "s3-bucket-public-write-prohibited"
  rule_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
}

# SNS topic for Config notifications
resource "aws_sns_topic" "config_notifier" {
  count = var.enable_config_rules ? 1 : 0
  name  = "config-compliant-changes"

  tags = var.default_tags
}

resource "aws_sns_topic_policy" "config_notifier" {
  count = var.enable_config_rules ? 1 : 0
  arn   = aws_sns_topic.config_notifier[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPublish"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.config_notifier[0].arn
      }
    ]
  })
}

output "config_aggregator_name" {
  description = "AWS Config aggregator for centralized compliance"
  value       = try(aws_config_configuration_aggregator.organization[0].name, null)
}

output "config_notification_topic" {
  description = "SNS topic for Config notifications"
  value       = try(aws_sns_topic.config_notifier[0].arn, null)
}
