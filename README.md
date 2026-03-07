# AWS Infrastructure - Terraform

Complete AWS multi-account infrastructure using Control Tower, Organizations, and Account Factory for Terraform (AFT).

## Quick Start

### 1. Copy Configuration

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. Customize Organization

Edit `terraform.tfvars`:
- **Organizational Units** - OU structure (Security, Infrastructure, Workloads, etc.)
- **AWS Accounts** - Member accounts to create (Audit, LogArchive, SharedServices, Network, AFT-Tooling, etc.)
- **Service Control Policies** - Organization policies (prevent leaving org, require MFA, etc.)
- **IAM Identity Center** - Permission sets (prod-admin, dev-engineer, platform-admin, security-audit)
- **Delegated Administrators** - Which accounts can manage org services (AFT, CloudTrail, Config, GuardDuty, etc.)

### 3. Ensure Prerequisites

Before deploying:
- AWS Organizations must be enabled (Terraform cannot create it without manual setup)
- AWS Control Tower must be manually enabled in AWS Console (takes 20-30 minutes)
- AWS credentials configured for management account

### 4. Deploy

```bash
./scripts/deploy.sh --auto-approve
```

**Time:** ~45-60 minutes total (control tower setup is automatic via Terraform)

---

## What Gets Created

| Component | Status | Prerequisite |
|-----------|--------|---------------|
| Terraform state backend (S3 + DynamoDB) | ✅ Automatic | None |
| AWS Organization | 📋 Manual then Terraform | Enable in AWS Console first |
| Control Tower landing zone | 📋 Manual then Terraform | Enable in AWS Console first |
| Organizational Units (OUs) | ✅ From terraform.tfvars | Control Tower enabled |
| AWS Accounts | ✅ From terraform.tfvars | Control Tower enabled |
| Service Control Policies | ✅ From terraform.tfvars | Control Tower enabled |
| IAM Identity Center | ✅ From terraform.tfvars | Control Tower auto-enables it |
| Account Factory for Terraform (AFT) | ✅ From terraform.tfvars | Control Tower enabled |
| CloudTrail | ✅ From terraform.tfvars | Can be disabled via config |
| AWS Config | ✅ From terraform.tfvars | Can be disabled via config |

---

## Deployment Sequence

Automatically ordered (no manual sequencing needed):

```
1. Bootstrap      → S3 + DynamoDB state backend
2. Control Tower  → Organization + landing zone
3. Organization   → OUs + accounts + policies + IAM IC
4. AFT            → Account provisioning pipeline
```

---

## Configuration

### terraform.tfvars (Root Level)

This is the **single source of truth** for all stack configuration. All modules (bootstrap, control-tower, org, aft) read from this file.

Edit the file copied from `terraform.tfvars.example`:

```hcl
# Primary region for all resources
region = "ca-central-1"

# Email domain for auto-generated account emails
account_email_domain = "your-domain.com"

# Define your organization structure
organizational_units = {
  security = {
    name          = "Security"
    parent_ou_key = null  # Root level
  }
  infrastructure = {
    name          = "Infrastructure"
    parent_ou_key = null
  }
  workload = {
    name          = "Workloads"
    parent_ou_key = null
  }
  prod = {
    name          = "Production"
    parent_ou_key = "workload"  # Nested under Workloads
  }
}

# Define member accounts to create
accounts = {
  log_archive = {
    email_local_part = "log-archive"
    name             = "LogArchive"
    parent_ou_key    = "security"
  }
  shared_services = {
    email_local_part = "shared-services"
    name             = "SharedServices"
    parent_ou_key    = "infrastructure"
  }
}

# Define Service Control Policies
scp_policies = {
  deny_leave_org = {
    description = "Prevent accounts from leaving the organization"
    content     = "{...json policy...}"
  }
}

# Attach policies to OUs or root
policy_attachments = {
  deny_leave_to_root = {
    policy_key  = "deny_leave_org"
    target_type = "ROOT"
  }
}

# Delegate service management to specific accounts
delegated_administrators = {
  aft_service = {
    account_key       = "aft_tooling"
    service_principal = "aft.amazonaws.com"
  }
}
```

### Environment Variables (Optional)

You can optionally set these in your shell or `.env` file:

```bash
AWS_PROFILE=management      # AWS CLI profile to use
AWS_REGION=ca-central-1    # Default region
```

---

## Deployment Modes

### Full Deployment (Recommended)

```bash
./scripts/deploy.sh --auto-approve
```

### Preview Only

```bash
./scripts/deploy.sh --plan-only
```

### Interactive

```bash
./scripts/deploy.sh
```

---

## Post-Deployment

After deployment completes:

1. **Review AWS account** for deployed resources
2. **Configure IAM Identity Center** - Manually add users and groups
3. **Create account requests** using Account Factory for Terraform

See [docs/control-tower-aft.md](docs/control-tower-aft.md) for operating model details.

---

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- New AWS management account (no existing organization)
- Permissions for Control Tower deployment

---

## Repository Structure

```
terraform/
├── terraform.tfvars      # Your organization configuration
├── main.tf               # Root module orchestration
├── variables.tf          # Input variables
├── versions.tf           # Provider versions
├── bootstrap/            # State backend (S3 + DynamoDB)
├── control-tower/        # Landing zone and organization
├── org/                  # OUs, accounts, policies, IAM IC
└── aft/                  # Account Factory

.env                       # Environment (git-ignored)
scripts/
└── deploy.sh        # Deployment script

docs/
├── control-tower-aft.md  # Operating model
├── organization-structure.md  # OU reference
├── workload-repo-strategy.md  # Account provisioning
└── codespaces-dotfiles.md    # Dev container setup
```

---

## Modules

**bootstrap/** - Terraform state management
- S3 bucket for state
- DynamoDB locking table

**control-tower/** - AWS landing zone
- Creates organization
- Deploys landing zone
- Enables IAM Identity Center

**org/** - Organization structure
- Organizational Units
- AWS Accounts
- Service Control Policies
- IAM Identity Center permission sets

**aft/** - Account Factory for Terraform
- Account request management
- Automated provisioning workflow

---

## Documentation

- [Operating Model](docs/control-tower-aft.md)
- [Organization Design](docs/organization-structure.md)
- [Workload Repositories](docs/workload-repo-strategy.md)
- [Dev Container Setup](docs/codespaces-dotfiles.md)

---

## Troubleshooting

### Control Tower deployment takes too long

This is normal - landing zone deployment typically takes 30-45 minutes. Monitor progress in AWS Console > AWS Control Tower.

### Permission errors

Ensure your AWS credentials have sufficient permissions:
- IAM, Organizations, Control Tower
- S3, DynamoDB, SSO

### State file corruption

```bash
cd terraform
rm -rf .terraform terraform.tfstate*
terraform init
terraform apply -var-file=terraform.tfvars
```

---

See `docs/` for additional documentation.
