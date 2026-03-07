# Root module - composes all child modules with proper dependencies

# Stage 1: Bootstrap - Create Terraform state management infrastructure
module "bootstrap" {
  source = "./bootstrap"

  region            = var.primary_region
  state_bucket_name = var.state_bucket_name
  lock_table_name   = var.lock_table_name
  default_tags      = var.default_tags
}

# Enforce sequencing: control_tower waits for bootstrap
locals {
  bootstrap_complete = module.bootstrap.state_bucket_name
}

# Stage 2: Control Tower - Create landing zone and AWS organization
module "control_tower" {
  source = "./control-tower"

  primary_region                         = var.primary_region
  enabled_regions                        = var.enabled_regions
  account_email_domain                   = var.account_email_domain
  audit_account_email                    = var.audit_account_email
  log_archive_account_email              = var.log_archive_account_email
  enable_guardrails                      = var.enable_guardrails
  organization_service_access_principals = var.organization_service_access_principals
  default_tags                           = var.default_tags
}

# Enforce sequencing: org waits for control_tower
locals {
  organization_id = module.control_tower.organization_id
}

# Stage 3: Organization - Create OUs, accounts, SCPs, and Identity Center permission sets
module "org" {
  source = "./org"

  region                                 = var.primary_region
  create_organization                    = false # Already created by Control Tower
  organization_feature_set               = var.organization_feature_set
  organization_service_access_principals = var.organization_service_access_principals
  organization_enabled_policy_types      = var.organization_enabled_policy_types
  organizational_units                   = var.organizational_units
  accounts                               = var.accounts
  scp_policies                           = var.scp_policies
  policy_attachments                     = var.policy_attachments
  delegated_administrators               = var.delegated_administrators
  account_email_domain                   = var.account_email_domain
  default_tags                           = var.default_tags
  enable_cloudtrail                      = var.enable_cloudtrail
  enable_config_rules                    = var.enable_config_rules
}

# Enforce sequencing: aft waits for org
locals {
  org_complete = module.org.organizational_units_flat
}

# Stage 4: AFT - AWS Account Factory for Terraform
module "aft" {
  source = "./aft"

  region       = var.primary_region
  aft_enabled  = var.aft_enabled
  default_tags = var.default_tags
}
