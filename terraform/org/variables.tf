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

variable "organizational_units" {
  description = "Map of OUs. If parent_ou_key is null, OU is created under root. Otherwise, under the referenced root-level OU key."
  type = map(object({
    name          = string
    parent_ou_key = optional(string)
  }))
  default = {}
}

variable "accounts" {
  description = "Map of AWS accounts to create in the organization"
  type = map(object({
    email                      = string
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
