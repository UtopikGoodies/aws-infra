# Organization Terraform - Ready State Setup

This directory contains everything needed to set up a production-ready AWS organization structure for Control Tower and AFT.

## Prerequisites

1. **AWS Management Account**: You must have access to a clean management account
2. **AWS Control Tower**: Must be enabled manually in the AWS console (not automated in Terraform)
3. **Terraform**: Version 1.0+
4. **AWS CLI**: Configured with management account credentials

## Architecture Overview

```
AWS Organization
├── Management Account (Terraform state, IAM Identity Center)
├── Security OU
│   ├── LogArchive Account (CloudTrail, central logging)
│   └── Audit Account (AWS Config aggregation, compliance)
├── SharedServices OU
│   ├── SharedServices Account (Platform infrastructure)
│   └── AFT-Tooling Account (AFT service deployment)
├── Production OU
│   └── [App accounts managed by AFT]
└── NonProduction OU
    ├── Staging
    └── Development / Sandbox
```

## What's Included

### 1. Organization Structure (`main.tf`)
- Root OUs: Security, SharedServices, Production, NonProduction
- Sub-OUs: Sandbox (under NonProduction)
- Recommended AWS accounts with proper segregation
- Service Control Policies (SCPs) for governance

### 2. IAM Identity Center (`identity-center.tf`)
- **Permission Sets** (pre-configured access patterns):
  - `dev-engineer`: PowerUser in non-prod (4h sessions)
  - `prod-read`: ReadOnly in prod (1h sessions)
  - `prod-admin`: Administrator in prod (1h sessions)
  - `platform-admin`: Administrator everywhere (4h sessions)
  - `security-audit`: Audit + SecurityAudit (2h sessions)

### 3. CloudTrail (`cloudtrail.tf`)
- Organization-wide CloudTrail logging
- Centralized S3 storage in LogArchive account
- CloudWatch integration for monitoring
- Log validation enabled for compliance

### 4. AWS Config (`config-aggregator.tf`)
- Organization-wide compliance monitoring
- Pre-configured rules:
  - CloudTrail enabled
  - IAM policies checked
  - Root account MFA enforced
  - S3 bucket access controls
  - EC2 Systems Manager integration
- SNS notifications for changes

### 5. Service Control Policies
- **deny_leave_org**: Prevent accounts from leaving
- **deny_delete_account**: Prevent account closure
- **require_mfa**: Enforce MFA in non-prod
- **deny_privileged_regions**: Restrict IAM operations to approved regions

### 6. Account Factory for Terraform (AFT) Requests
Example account requests included:
- `shared-services-prod`: Shared platform services
- `app-platform-prod`: Production application account
- `app-platform-staging`: Staging/pre-prod account
- `sandbox`: Experimentation account

## Deployment Steps

### Phase 1: Enable Control Tower (Manual)

1. Sign in to AWS Management Console
2. Navigate to AWS Control Tower
3. Click "Set up landing zone"
4. Select your target regions (recommended: ca-central-1, us-east-1)
5. Configure baseline guardrails
6. Review and deploy (takes 20-30 minutes)

### Phase 2: Prepare Terraform Backend

```bash
cd terraform/bootstrap
terraform init
terraform plan
terraform apply
```

This creates:
- S3 bucket for Terraform state
- DynamoDB table for state locking

### Phase 3: Deploy Organization Structure

```bash
cd terraform/org
terraform init \
  -backend-config="bucket=<state-bucket-name>" \
  -backend-config="key=org/terraform.tfstate" \
  -backend-config="region=ca-central-1" \
  -backend-config="dynamodb_table=terraform-state-locks"

terraform plan
terraform apply
```

Or use the convenience script:

```bash
cd /workspaces/aws-infra
./scripts/deploy.sh --auto-approve
```

### Phase 4: Deploy AFT (AWS-Managed)

1. Navigate to AWS Account Factory for Terraform in AWS console
2. Grant AFT API access to Management account
3. Create CodePipeline in AFT-Tooling account
4. Reference account requests from `terraform/aft/account-requests/`

Or follow the [AWS AFT Reference Architecture](https://docs.aws.amazon.com/controltower/latest/userguide/aft-getting-started.html)

## Key Terraform Files

| File | Purpose |
|------|---------|
| `main.tf` | Organization, OUs, accounts, SCPs |
| `variables.tf` | Input variables and configuration |
| `identity-center.tf` | IAM Identity Center permission sets |
| `cloudtrail.tf` | Centralized audit logging |
| `config-aggregator.tf` | Compliance monitoring |
| `outputs.tf` | Output values referenced by other stacks |
| `providers.tf` | AWS provider configuration |
| `versions.tf` | Terraform version constraints |

## Configuration

### Email Domain
Update `account_email_domain` in `terraform.tfvars`:
```hcl
account_email_domain = "your-company.com"
```

Accounts will receive emails like: `aws+account-name@your-company.com`

### Custom Accounts
Add accounts to `terraform.tfvars`:
```hcl
accounts = {
  my_custom_account = {
    email_local_part = "my-custom"
    name             = "My Custom Account"
    parent_ou_key    = "prod"  # or "nonprod", "security", "shared"
    tags = {
      environment = "prod"
      team        = "engineering"
    }
  }
}
```

### Custom SCPs
Add policies to `terraform.tfvars`:
```hcl
scp_policies = {
  my_policy = {
    description = "My custom policy"
    content     = jsonencode({...})
  }
}
```

## Outputs

After deployment, you'll have:

```
Organization ID: o-xxx...
Root ID: r-xxxx...
Organizational Units:
  - security: ou-xxxx...
  - shared: ou-xxxx...
  - prod: ou-xxxx...
  - nonprod: ou-xxxx...
  - sandbox: ou-xxxx...

Accounts:
  - audit: 222222222222
  - log_archive: 333333333333
  - shared_services: 444444444444
  - aft_tooling: 555555555555

Identity Center Instance: arn:aws:sso:::instance/ssoins-xxx...
Permission Sets: dev-engineer, prod-read, prod-admin, platform-admin, security-audit

CloudTrail Bucket: cloudtrail-logs-xxx-...
Config Aggregator: organization-aggregator
```

## Security Considerations

✅ **Implemented**:
- MFA enforcement via SCP
- Account isolation with OUs
- Service Control Policies for guardrails
- CloudTrail for audit logging
- AWS Config for compliance monitoring
- Centralized permission management

⚠️ **Next Steps** (outside Terraform):
1. Enable MFA for root account
2. Configure Identity Center user sync (Directory or External IDP)
3. Set up CloudTrail alarms for suspicious activity
4. Configure Config rules remediation
5. Enable GuardDuty across all accounts

## Troubleshooting

### Identity Center not available
- Wait 24 hours after Control Tower setup
- Confirm you're in a Control Tower enabled region

### CloudTrail deployment fails
- Ensure CloudTrail API access is enabled in organization
- Check S3 bucket policy permissions

### Config rules not running
- Verify AWS Config is enabled in member accounts
- Check IAM permissions in config-delegated account

## Further Reading

- [AWS Control Tower Best Practices](https://docs.aws.amazon.com/controltower/latest/userguide/best-practices.html)
- [Account Factory for Terraform overview](https://docs.aws.amazon.com/controltower/latest/userguide/aft-getting-started.html)
- [Multi-account strategy](https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/)
- [Service Control Policies](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)

## Support

For issues or questions, consult:
1. AWS Control Tower documentation
2. Terraform AWS provider documentation
3. Your organization's Terraform standards (in adjacent docs/)
