# AWS Control Tower Module

This module is part of the unified `aws-infra` deployment and should **not be deployed separately**. It is orchestrated by the root module in the parent `terraform/` directory.

## Overview

The Control Tower module enables and configures AWS Control Tower with complete infrastructure-as-code automation. This is deployed as the second stage (after bootstrap), before AWS Organizations and AFT.

## What This Module Creates

### Core Resources
- ✅ **AWS Organization** with `ALL` feature set
- ✅ **Control Tower Landing Zone** with multi-region support
- ✅ **Audit Account** (managed by Control Tower)
- ✅ **Log Archive Account** (managed by Control Tower)
- ✅ **Baseline guardrails** for governance

### Logging & Security
- ✅ **CloudTrail**: Organization-wide audit trail
- ✅ **CloudWatch**: Integrated logging for Control Tower events
- ✅ **S3 encryption & versioning**: Enabled
- ✅ **Delegated administrators**: CloudTrail, Config, GuardDuty

### Service Enablement
- ✅ **CloudTrail API**: For organization-wide logging
- ✅ **AWS Config API**: For compliance monitoring
- ✅ **GuardDuty API**: For threat detection
- ✅ **Control Tower API**: For landing zone orchestration

## Configuration

All configuration is managed from the root-level `terraform.tfvars` file. This module reads from:

```hcl
# terraform.tfvars (repository root)
primary_region                         = "ca-central-1"
enabled_regions                        = ["ca-central-1", "us-east-1"]
account_email_domain                   = "your-company.com"
audit_account_email                    = "aws-audit@your-company.com"
log_archive_account_email              = "aws-logs@your-company.com"
enable_guardrails                      = true
organization_service_access_principals = [...]
```

## Deployment

**Do not deploy this module directly.** Deploy from the repository root instead:

```bash
cd /workspaces/aws-infra
./scripts/deploy.sh --auto-approve
```

This will:
1. Bootstrap Terraform state (S3 + DynamoDB)
2. Deploy Control Tower landing zone (this module)
3. Deploy Organization structure (OUs, accounts, policies)
4. Deploy Account Factory for Terraform (AFT)

## Manual Deployment (Advanced)

If you need to deploy this module separately, initialize from the root:

```bash
cd /workspaces/aws-infra/terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

**Note**: First-time deployment takes **30-45 minutes** for Control Tower to fully initialize.

## Deployment Timeline

1. **AWS Organization created** (5 min)
   - Enables All Features mode
   - Registers delegated administrators
   
2. **Control Tower landing zone deployed** (30 min)
   - Provisions Audit account
   - Provisions LogArchive account
   - Creates root OU
   - Configures CloudTrail
   - Deploys guardrails
   
3. **IAM Identity Center enabled** (automatic)
   - Ready for permission set configuration
   
4. **Resource outputs generated** (~1 min)

**Total time: ~35-45 minutes**

## Notes

- Control Tower deployment cannot be undone easily - plan carefully before applying
- The `create_organization = false` setting in `terraform.tfvars` assumes Control Tower is already enabled
- All subsequent modules (org/, aft/) depend on Control Tower being operational
- After deployment, manually configure IAM Identity Center users and groups in AWS Console

## Integration with Root Module

This module is part of the unified deployment:

```
1. terraform/bootstrap       → State bucket, locks (automatic)
                              ↓
2. terraform/control-tower   → Organization, landing zone (this module)
                              ↓
3. terraform/org             → OUs, accounts, policies (automatic)
                              ↓
4. terraform/aft             → Account requests, AFT setup (automatic)
```

All stages deploy atomically from `/workspaces/aws-infra/scripts/deploy.sh`.

## Further Reading

- [AWS Control Tower User Guide](https://docs.aws.amazon.com/controltower/latest/userguide/)
- [Terraform AWS Provider - Control Tower](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/controltower_landing_zone)
- [Control Tower Best Practices](https://docs.aws.amazon.com/controltower/latest/userguide/best-practices.html)
