variable "primary_region" {
  description = "Primary region where Control Tower landing zone is deployed"
  type        = string
  default     = "ca-central-1"
}

variable "enabled_regions" {
  description = "List of AWS regions where Control Tower will be enabled"
  type        = list(string)
  default     = ["ca-central-1"]
}

variable "default_tags" {
  description = "Default tags applied to all resources"
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "aws-infra"
  }
}

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

variable "organization_service_access_principals" {
  description = "AWS service principals to enable in organization"
  type        = list(string)
  default     = []
}

variable "enable_guardrails" {
  description = "Enable Control Tower guardrails"
  type        = bool
  default     = true
}

variable "guardrail_level" {
  description = "Guardrail compliance level: STANDARD, STRICT"
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "STRICT"], var.guardrail_level)
    error_message = "Guardrail level must be STANDARD or STRICT."
  }
}

variable "create_organization" {
  description = "Whether to create AWS Organization (set to false if it already exists)"
  type        = bool
  default     = true
}
