# Root module variables - passed through to child modules

variable "primary_region" {
  description = "Primary AWS region for all resources"
  type        = string
  default     = "ca-central-1"
}

variable "enabled_regions" {
  description = "AWS regions where Control Tower will be enabled"
  type        = list(string)
  default     = ["ca-central-1"]
}

variable "default_tags" {
  description = "Default tags applied to all resources"
  type        = map(string)
  default = {
    managed_by  = "terraform"
    project     = "aws-infra"
    environment = "production"
  }
}

# Bootstrap variables
variable "state_bucket_name" {
  description = "S3 bucket name for Terraform state (auto-generated if empty)"
  type        = string
  default     = ""
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "terraform-state-locks"
}

# Control Tower variables
variable "account_email_domain" {
  description = "Domain used for auto-generated account emails"
  type        = string
  default     = "example.com"
}

variable "audit_account_email" {
  description = "Email for Audit account (optional - auto-generated if not set)"
  type        = string
  default     = null
}

variable "log_archive_account_email" {
  description = "Email for Log Archive account (optional - auto-generated if not set)"
  type        = string
  default     = null
}

variable "enable_guardrails" {
  description = "Enable Control Tower guardrails"
  type        = bool
  default     = true
}

# Organization variables
variable "create_organization" {
  description = "Create new organization or use existing"
  type        = bool
  default     = false
}

variable "organization_feature_set" {
  description = "Organization feature set (ALL or CONSOLIDATED_BILLING)"
  type        = string
  default     = "ALL"
}

variable "organization_service_access_principals" {
  description = "AWS service principals to enable"
  type        = list(string)
  default = [
    "aft.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "controltower.amazonaws.com",
    "guardduty.amazonaws.com"
  ]
}

variable "organizational_units" {
  description = "Map of organizational units to create"
  type = map(object({
    name          = string
    parent_ou_key = optional(string)
  }))
  default = {
    security = {
      name          = "Security"
      parent_ou_key = null
    }
    shared = {
      name          = "Shared"
      parent_ou_key = null
    }
    production = {
      name          = "Production"
      parent_ou_key = null
    }
    non_production = {
      name          = "Non-Production"
      parent_ou_key = null
    }
    sandbox = {
      name          = "Sandbox"
      parent_ou_key = "non_production"
    }
  }
}

variable "accounts" {
  description = "AWS accounts to create in the organization"
  type = map(object({
    email_local_part           = optional(string)
    email                      = optional(string)
    name                       = string
    parent_ou_key              = string
    role_name                  = optional(string, "OrganizationAccountAccessRole")
    iam_user_access_to_billing = optional(string, "ALLOW")
    close_on_deletion          = optional(bool, false)
    tags                       = optional(map(string), {})
  }))
  default = {}
}

variable "scp_policies" {
  description = "Service Control Policies to create"
  type = map(object({
    description = string
    content     = string
    tags        = optional(map(string), {})
  }))
  default = {}
}

variable "policy_attachments" {
  description = "SCP policy attachments"
  type = map(object({
    policy_key  = string
    target_type = string # ROOT, OU, or ACCOUNT
    target_key  = optional(string)
  }))
  default = {}
}

variable "delegated_administrators" {
  description = "Delegated administrator accounts for AWS services"
  type = map(object({
    account_key       = string
    service_principal = string
  }))
  default = {}
}

variable "organization_enabled_policy_types" {
  description = "Organization policy types to enable"
  type        = list(string)
  default     = ["SERVICE_CONTROL_POLICY"]
}

variable "aft_enabled" {
  description = "Enable AWS Account Factory for Terraform (AFT)"
  type        = bool
  default     = true
}

# Feature toggles for selective deployment
variable "enable_cloudtrail" {
  description = "Deploy organization-wide CloudTrail (requires CloudTrail service access enabled in AWS Organizations)"
  type        = bool
  default     = false
}

variable "enable_config_rules" {
  description = "Deploy AWS Config organization managed rules (requires AWS Config setup on all accounts)"
  type        = bool
  default     = false
}
