output "state_bucket_name" {
  description = "S3 bucket name for Terraform state"
  value       = aws_s3_bucket.tf_state.id
}

output "lock_table_name" {
  description = "DynamoDB table name for Terraform state locks"
  value       = aws_dynamodb_table.tf_lock.name
}

output "management_account_id" {
  description = "AWS management/root account ID"
  value       = data.aws_caller_identity.current.account_id
}
