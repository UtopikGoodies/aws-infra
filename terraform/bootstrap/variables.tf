variable "region" {
  description = "AWS region for backend resources"
  type        = string
  default     = "eu-west-1"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state"
  type        = string
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "terraform-state-locks"
}

variable "default_tags" {
  description = "Default tags applied to created resources"
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "aws-infra"
  }
}
