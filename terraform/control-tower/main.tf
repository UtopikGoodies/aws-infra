# AWS Control Tower Landing Zone setup via Terraform
# 
# This module enables and configures AWS Control Tower with full Terraform automation.
# Control Tower is the foundation for multi-account governance before AFT deployment.

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Enable Control Tower - Deploy landing zone
resource "aws_controltower_landing_zone" "main" {
  manifest_json = jsonencode({
    governanceConfiguration = {
      logging = {
        baselineCloudWatchLogsEnabled = true
        baselineS3BucketEnabled       = true
      }
      securityControl = {
        enabledControls = []
      }
    }
    organizationStructure = {
      rootAccount = {
        accountEmail = data.aws_caller_identity.current.account_id
      }
      managementAccount = {
        accountEmail = data.aws_caller_identity.current.account_id
      }
    }
  })

  version = "3.3"

  tags = var.default_tags
}

# S3 bucket for Control Tower central logging
resource "aws_s3_bucket" "central_logging" {
  bucket = "aws-controltower-logs-${data.aws_caller_identity.current.account_id}-${var.primary_region}"

  tags = merge(
    var.default_tags,
    {
      Name        = "Control Tower Central Logging"
      Environment = "security"
    }
  )
}

resource "aws_s3_bucket_versioning" "central_logging" {
  bucket = aws_s3_bucket.central_logging.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "central_logging" {
  bucket = aws_s3_bucket.central_logging.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "central_logging" {
  bucket = aws_s3_bucket.central_logging.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "central_logging" {
  bucket = aws_s3_bucket.central_logging.id

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
        Resource = aws_s3_bucket.central_logging.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.central_logging.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# S3 bucket for Control Tower logging logs
resource "aws_s3_bucket" "central_logging_logs" {
  bucket = "aws-controltower-logs-logs-${data.aws_caller_identity.current.account_id}-${var.primary_region}"

  tags = merge(
    var.default_tags,
    {
      Name        = "Control Tower Logging Logs"
      Environment = "security"
    }
  )
}

resource "aws_s3_bucket_versioning" "central_logging_logs" {
  bucket = aws_s3_bucket.central_logging_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "central_logging_logs" {
  bucket = aws_s3_bucket.central_logging_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "central_logging_logs" {
  bucket = aws_s3_bucket.central_logging_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "aws-controltower-cloudtrail-${data.aws_caller_identity.current.account_id}-${var.primary_region}"

  tags = merge(
    var.default_tags,
    {
      Name        = "Control Tower CloudTrail Logs"
      Environment = "security"
    }
  )
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

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
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# Create organization if it doesn't exist (Control Tower requires organization)
resource "aws_organizations_organization" "main" {
  feature_set = "ALL"
  aws_service_access_principals = concat(
    var.organization_service_access_principals,
    [
      "cloudtrail.amazonaws.com",
      "controltower.amazonaws.com",
      "config.amazonaws.com",
      "guardduty.amazonaws.com"
    ]
  )
  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]
}

# Enable required AWS services in organization
resource "aws_organizations_delegated_administrator" "controltower" {
  account_id        = data.aws_caller_identity.current.account_id
  service_principal = "controltower.amazonaws.com"

  depends_on = [aws_organizations_organization.main]
}

resource "aws_organizations_delegated_administrator" "cloudtrail" {
  account_id        = data.aws_caller_identity.current.account_id
  service_principal = "cloudtrail.amazonaws.com"

  depends_on = [aws_organizations_organization.main]
}

resource "aws_organizations_delegated_administrator" "config" {
  account_id        = data.aws_caller_identity.current.account_id
  service_principal = "config.amazonaws.com"

  depends_on = [aws_organizations_organization.main]
}
