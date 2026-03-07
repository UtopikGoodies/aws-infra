terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Uncomment after first bootstrap run to store state in S3
  # backend "s3" {
  #   bucket         = "tf-state-ACCOUNT-ID-XXXXXXXX"
  #   key            = "aws-infra/terraform.tfstate"
  #   region         = "ca-central-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-locks"
  # }
}

provider "aws" {
  region = var.primary_region

  default_tags {
    tags = var.default_tags
  }
}
