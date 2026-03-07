variable "region" {
  description = "AWS region used for API calls"
  type        = string
  default     = "ca-central-1"
}

variable "default_tags" {
  description = "Default tags applied to created resources"
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "aws-infra"
  }
}

variable "account_email_domain" {
  description = "Domain used to auto-generate account emails as aws+<local_part>@<domain> when account.email is not set."
  type        = string
  default     = "example.com"
}

variable "create_organization" {
  description = "When true, Terraform creates the AWS Organization in this management account. When false, it uses the existing organization."
  type        = bool
  default     = false
}

variable "organization_feature_set" {
  description = "Feature set for organization creation. Used only when create_organization is true."
  type        = string
  default     = "ALL"
}

variable "organization_service_access_principals" {
  description = "AWS service principals to enable trusted access for. Used only when create_organization is true."
  type        = list(string)
  default     = []
}

variable "organization_enabled_policy_types" {
  description = "Organization policy types to enable. Used only when create_organization is true."
  type        = list(string)
  default     = ["SERVICE_CONTROL_POLICY"]
}

variable "organizational_units" {
  description = "Map of OUs. If parent_ou_key is null, OU is created under root. Otherwise, under the referenced root-level OU key."
  type = map(object({
    name          = string
    parent_ou_key = optional(string)
  }))
  default = {}
}

variable "accounts" {
  description = "Map of AWS accounts to create in the organization. If email is omitted, it is generated from account_email_domain and email_local_part (or account key)."
  type = map(object({
    email                      = optional(string)
    email_local_part           = optional(string)
    name                       = string
    parent_ou_key              = optional(string)
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
  description = "SCP attachments: target_type must be ROOT, OU, or ACCOUNT"
  type = map(object({
    policy_key  = string
    target_type = string
    target_key  = optional(string)
  }))
  default = {}
}

variable "delegated_administrators" {
  description = "Delegated administrator assignments by service principal"
  type = map(object({
    account_key       = string
    service_principal = string
  }))
  default = {}
}

variable "enable_cloudtrail" {
  description = "Deploy organization-wide CloudTrail (requires CloudTrail service access enabled)"
  type        = bool
  default     = false
}

variable "enable_config_rules" {
  description = "Deploy AWS Config organization managed rules (requires Config setup on all accounts)"
  type        = bool
  default     = false
}
