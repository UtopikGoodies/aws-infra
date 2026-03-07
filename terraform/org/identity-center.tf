# IAM Identity Center Permission Sets and Assignments
# Centrally define access patterns for all member accounts
# Note: Identity Center must be enabled through Control Tower first
# This sub-stack should only run AFTER Control Tower deployment completes

# Data source to get Identity Center instance
# NOTE: Will be empty until Control Tower is deployed and enabled this service
data "aws_ssoadmin_instances" "this" {}

# Permission Sets - Define access control patterns
# Only create if Identity Center is available
resource "aws_ssoadmin_permission_set" "dev_engineer" {
  count            = length(data.aws_ssoadmin_instances.this.arns) > 0 ? 1 : 0
  name             = "dev-engineer"
  description      = "Developer access to non-production accounts (4h sessions)"
  instance_arn     = data.aws_ssoadmin_instances.this.arns[0]
  session_duration = "PT4H"

  tags = var.default_tags
}

resource "aws_ssoadmin_permission_set" "prod_read" {
  count            = length(data.aws_ssoadmin_instances.this.arns) > 0 ? 1 : 0
  name             = "prod-read"
  description      = "Read-only access to production accounts (1h sessions)"
  instance_arn     = data.aws_ssoadmin_instances.this.arns[0]
  session_duration = "PT1H"

  tags = var.default_tags
}

resource "aws_ssoadmin_permission_set" "prod_admin" {
  count            = length(data.aws_ssoadmin_instances.this.arns) > 0 ? 1 : 0
  name             = "prod-admin"
  description      = "Administrator access to production accounts (1h sessions)"
  instance_arn     = data.aws_ssoadmin_instances.this.arns[0]
  session_duration = "PT1H"

  tags = var.default_tags
}

resource "aws_ssoadmin_permission_set" "platform_admin" {
  count            = length(data.aws_ssoadmin_instances.this.arns) > 0 ? 1 : 0
  name             = "platform-admin"
  description      = "Administrator access across all accounts for platform team (4h sessions)"
  instance_arn     = data.aws_ssoadmin_instances.this.arns[0]
  session_duration = "PT4H"

  tags = var.default_tags
}

resource "aws_ssoadmin_permission_set" "security_audit" {
  count            = length(data.aws_ssoadmin_instances.this.arns) > 0 ? 1 : 0
  name             = "security-audit"
  description      = "Security audit access with read-only + audit capabilities (2h sessions)"
  instance_arn     = data.aws_ssoadmin_instances.this.arns[0]
  session_duration = "PT2H"

  tags = var.default_tags
}

# Attach AWS managed policies to permission sets
resource "aws_ssoadmin_managed_policy_attachment" "dev_engineer_policy" {
  count              = length(data.aws_ssoadmin_instances.this.arns) > 0 ? 1 : 0
  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.dev_engineer[0].arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "prod_read_policy" {
  count              = length(data.aws_ssoadmin_instances.this.arns) > 0 ? 1 : 0
  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.prod_read[0].arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "prod_admin_policy" {
  count              = length(data.aws_ssoadmin_instances.this.arns) > 0 ? 1 : 0
  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.prod_admin[0].arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "platform_admin_policy" {
  count              = length(data.aws_ssoadmin_instances.this.arns) > 0 ? 1 : 0
  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.platform_admin[0].arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_ssoadmin_managed_policy_attachment" "security_audit_base" {
  count              = length(data.aws_ssoadmin_instances.this.arns) > 0 ? 1 : 0
  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.security_audit[0].arn
  managed_policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

# Outputs for reference
output "identity_center_instance_arn" {
  description = "ARN of the Identity Center instance"
  value       = length(data.aws_ssoadmin_instances.this.arns) > 0 ? data.aws_ssoadmin_instances.this.arns[0] : null
}

output "permission_sets" {
  description = "Configured permission sets"
  value = length(data.aws_ssoadmin_instances.this.arns) > 0 ? {
    dev_engineer   = aws_ssoadmin_permission_set.dev_engineer[0].arn
    prod_read      = aws_ssoadmin_permission_set.prod_read[0].arn
    prod_admin     = aws_ssoadmin_permission_set.prod_admin[0].arn
    platform_admin = aws_ssoadmin_permission_set.platform_admin[0].arn
    security_audit = aws_ssoadmin_permission_set.security_audit[0].arn
  } : {}
}
