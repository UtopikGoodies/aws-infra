# Central CloudTrail configuration for organization-wide logging
# Logs are stored in the LogArchive account
# Set enable_cloudtrail = true to deploy (requires CloudTrail service access enabled in AWS Organizations)

data "aws_caller_identity" "current" {}

# Create S3 bucket for CloudTrail logs
# This would typically be managed in a separate log-archive account
# but is documented here as part of the organization setup pattern

resource "aws_cloudtrail" "organization" {
  count = var.enable_cloudtrail ? 1 : 0
  depends_on = [
    aws_s3_bucket_policy.cloudtrail_logs[0]
  ]

  name                          = "organization-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs[0].id
  is_multi_region_trail         = true
  is_organization_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  tags = var.default_tags
}

# S3 bucket for storing CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_logs" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = "cloudtrail-logs-${data.aws_caller_identity.current.account_id}-${var.region}"

  tags = merge(
    var.default_tags,
    {
      name        = "cloudtrail-logs"
      description = "Centralized CloudTrail logs for organization"
    }
  )
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs[0].arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# CloudWatch Logs group for CloudTrail (optional - for future use)
# Uncomment if you want to integrate CloudTrail with CloudWatch Logs
#
# resource "aws_cloudwatch_log_group" "cloudtrail" {
#   name              = "/aws/cloudtrail/organization"
#   retention_in_days = 30
#   tags              = var.default_tags
# }
#
# resource "aws_iam_role" "cloudtrail_cloudwatch_logs" {
#   name = "cloudtrail-cloudwatch-logs-role"
#   assume_role_policy = jsonencode({...})
# }

output "cloudtrail_bucket_name" {
  description = "S3 bucket for CloudTrail logs"
  value       = try(aws_s3_bucket.cloudtrail_logs[0].id, null)
}
