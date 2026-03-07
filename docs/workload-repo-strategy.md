# Workload repository strategy

This guide outlines how to organize separate infrastructure repos for workloads while keeping them aligned with the central `aws-infra` platform/governance repo.

## Repository taxonomy

```
aws-infra                          # ← You are here
├── Platform governance, org structure, AFT requests, shared modules
├── State: bootstrap + org-level only
└── Access: platform engineering team (strict)

aws-terraform-modules             # Shared modules library
├── vpc, iam-baseline, observability, etc.
└── Published/versioned modules consumed by workloads

acme-platform-api                 # Example workload repo
├── App infrastructure for platform-api service
├── State: prod + staging accounts
└── Access: platform-api team + platform-eng (via code)

acme-data-lake                     # Example workload repo
├── Data pipeline infrastructure
├── State: dedicated data accounts
└── Access: data team + platform-eng (via code)

acme-shared-services              # Optional: shared resources (VPC, observability, etc.)
├── Environment-level shared infra
├── State: shared services account
└── Access: platform-eng + relevant teams
```

## Folder structure per workload repo

```
acme-platform-api/
├── .github/workflows/            # CI/CD pipeline
│   ├── terraform-validate.yml
│   ├── terraform-plan.yml
│   └── terraform-apply.yml
├── .devcontainer/devcontainer.json
├── .gitignore
├── terraform/
│   ├── environments/
│   │   ├── staging/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── terraform.tfvars
│   │   └── prod/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── terraform.tfvars
│   └── modules/
│       ├── eks-cluster/
│       ├── rds-database/
│       └── alb/
├── docs/
│   ├── architecture.md
│   ├── runbook.md
│   └── team-onboarding.md
└── README.md
```

## Terraform state key conventions

Keep state keys organized by environment + region for clarity and safety.

```bash
# Workload state (in shared platform S3 bucket)
s3://all-terraform-state/acme-platform-api/prod/us-east-1/terraform.tfstate
s3://all-terraform-state/acme-platform-api/staging/us-east-1/terraform.tfstate
s3://all-terraform-state/acme-data-lake/prod/ca-center-1/terraform.tfstate

# Bootstrap state (management account)
s3://all-terraform-state/bootstrap/terraform.tfstate
```

**Backend config pattern** (`environments/prod/backend-config.hcl`):

```hcl
bucket         = "all-terraform-state"
key            = "acme-platform-api/prod/us-east-1/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-state-locks"
encrypt        = true
```

Initialize each environment:

```bash
cd terraform/environments/prod
terraform init -backend-config=backend-config.hcl
terraform plan
terraform apply
```

## CI/CD pipeline pattern

**Terraform validate** (on every commit):
- `terraform fmt -check`
- `terraform validate`
- `terraform plan` (dry-run, no apply)
- Optional: Checkov or Tfsec scanning for policy violations

**Terraform apply** (on merge to main, with approvals):
- Require 2 approvers for production changes
- Staging auto-applies on main
- Prod requires manual approval + change window

**Example GitHub Actions workflow**:

```yaml
name: terraform-plan

on:
  pull_request:
    paths:
      - 'terraform/**'

jobs:
  plan:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [staging, prod]
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.6.6

      - name: Terraform Format Check
        run: terraform fmt -check -recursive terraform/

      - name: Terraform Validate
        run: |
          cd terraform/environments/${{ matrix.environment }}
          terraform init -backend=false
          terraform validate

      - name: Terraform Plan
        run: |
          cd terraform/environments/${{ matrix.environment }}
          terraform init -backend-config=backend-config.hcl
          terraform plan -out=tfplan.binary
        env:
          AWS_ROLE_ARN: ${{ secrets.AWS_ROLE_ARN }}
          AWS_WEB_IDENTITY_TOKEN: ${{ secrets.OIDC_TOKEN }}

      - name: Comment PR with plan
        uses: actions/github-script@v6
        with:
          script: |
            // Post plan output to PR comment
```

## Account strategy integration

**AFT account requests** — use `aws-infra` repo:

1. Platform team creates account request in `aws-infra/terraform/aft/account-requests/acme-platform-api-prod`.
2. AFT provisions account and applies any shared baseline (IAM, security hub, etc.).
3. Workload team gets account ID in landing zone ready.

**Workload initialization** — use workload repo:

1. Workload team clones `acme-platform-api`.
2. Updates `terraform/environments/prod/terraform.tfvars` with account ID from AFT.
3. Sets up AWS credentials/OIDC in GitHub Actions.
4. Runs `terraform init` + `terraform plan` to bootstrap workload.

## Module sharing strategy

### Option A: Centralized modules repo
- Create `aws-terraform-modules` repo with reusable stacks (VPC, EKS, RDS, etc.).
- Publish versions (Git tags or Terraform Registry).
- Workloads reference modules like:
  ```hcl
  module "vpc" {
    source = "git::https://github.com/UtopikGoodies/aws-terraform-modules.git//vpc?ref=v1.0.0"
    cidr_block = var.vpc_cidr
  }
  ```

### Option B: Inline modules
- Keep small, workload-specific modules in each workload repo under `terraform/modules/`.
- Share common patterns via copy-paste or Terraform Registry.

### Option C: Hybrid
- Centralized modules for infrastructure-as-a-service patterns (VPC, database, observability).
- Inline modules for app-specific customization.

**Recommendation**: Start with **Option C** — centralize VPC, security, observability; keep app-specific logic inline.

## Access control pattern

Use AWS IAM + GitHub OIDC to tie workload repos to specific AWS accounts.

**GitHub OIDC trust policy** (in each workload account):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:UtopikGoodies/acme-platform-api:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

Workload repos assume this role automatically in CI/CD—no static credentials needed.

## Drift detection and remediation

Add recurring Terraform plan runs (daily or weekly) to detect drift:

```yaml
name: terraform-drift-check
on:
  schedule:
    - cron: '0 6 * * 1'  # Monday 6 AM UTC

jobs:
  drift:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          cd terraform/environments/prod
          terraform init -backend-config=backend-config.hcl
          terraform plan -out=drift.plan
      - name: Alert if drift detected
        if: failure()
        run: curl -X POST ${{ secrets.SLACK_WEBHOOK }} -d 'Drift detected in acme-platform-api!'
```

## Guardrails summary

- **Use separate repos** for different workloads/teams (not monorepo per workload).
- **Share modules** centrally, state separately.
- **Lock state** with DynamoDB by default.
- **Validate early** with pre-commit hooks and GitHub CI.
- **Require approval** for production, auto-apply staging.
- **Use OIDC** for CI/CD, never static IAM credentials.
- **Audit drift** regularly; alert on unexpected changes.

## Example: onboarding a new workload

1. Platform team creates AFT account request in `aws-infra`:
   ```bash
   mkdir terraform/aft/account-requests/acme-ml-platform-prod
   cp terraform/aft/account-requests/template/request.auto.tfvars.json \
      terraform/aft/account-requests/acme-ml-platform-prod/request.auto.tfvars.json
   ```

2. AFT provisions account and team gets account ID.

3. ML team creates new repo `acme-ml-platform`:
   ```bash
   git clone https://github.com/UtopikGoodies/aws-terraform-modules.git
   # (template from existing workload repo)
   ```

4. ML team updates state key and account IDs:
   ```hcl
   # terraform/environments/prod/backend-config.hcl
   key = "acme-ml-platform/prod/us-west-2/terraform.tfstate"
   
   # terraform/environments/prod/terraform.tfvars
   account_id = "123456789012"  # from AFT output
   ```

5. ML team sets up OIDC trust in workload account.

6. First PR runs plan; approval + merge applies to prod.

Done—fully separated, auditable, and safe.
