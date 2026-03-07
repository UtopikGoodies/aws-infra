provider "aws" {
  region = var.primary_region

  default_tags {
    tags = var.default_tags
  }
}
