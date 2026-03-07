variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "aws-infra"
  }
}

variable "aft_enabled" {
  description = "Whether AFT account requests should be processed"
  type        = bool
  default     = true
}
