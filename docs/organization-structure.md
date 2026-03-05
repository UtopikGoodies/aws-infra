# Recommended AWS Organization structure

This document outlines what your AWS Organization should look like after fully implementing Control Tower, AFT, and this IaC approach.

## AWS Organization hierarchy

```
AWS Organization (root)
├── Root (management account)
│   ├── Account: Management-Account (ID: 111111111111)
│   │   ├── Role: OrganizationAccountAccessRole
│   │   ├── Service: Control Tower
│   │   ├── Service: IAM Identity Center
│   │   ├── Service: AFT (Account Factory for Terraform)
│   │   └── S3: Terraform state bucket (all-terraform-state)
│   │
│   └── OUs (Organizational Units)
│       ├── Security
│       │   ├── Account: Audit (ID: 222222222222)
│       │   │   └── Role: prod-admin (via Identity Center)
│       │   │
│       │   └── Account: LogArchive (ID: 333333333333)
│       │       └── Role: prod-admin (via Identity Center)
│       │
│       ├── SharedServices / Shared
│       │   ├── Account: SharedServices-Prod (ID: 444444444444)
│       │   │   ├── VPC (central)
│       │   │   ├── DNS (Route53)
│       │   │   ├── Observability (CloudWatch central)
│       │   │   └── Role: platform-admin (via Identity Center)
│       │   │
│       │   └── Account: AFT-Tooling (ID: 555555555555)
│       │       ├── Service: AFT deployment
│       │       ├── CodePipeline (AFT pipelines)
│       │       └── Role: platform-admin (via Identity Center)
│       │
│       ├── Production
│       │   ├── Account: acme-platform-api-prod (ID: 666666666666)
│       │   │   ├── Workload: Platform API
│       │   │   ├── Permission Set: prod-admin (platform-api-team)
│       │   │   ├── Permission Set: prod-read (prod-support)
│       │   │   └── OIDC: GitHub (acme-platform-api repo)
│       │   │
│       │   ├── Account: acme-data-lake-prod (ID: 777777777777)
│       │   │   ├── Workload: Data Pipeline
│       │   │   ├── Permission Set: prod-admin (data-team)
│       │   │   ├── Permission Set: prod-read (analytics-team)
│       │   │   └── OIDC: GitHub (acme-data-lake repo)
│       │   │
│       │   └── Account: acme-ml-platform-prod (ID: 888888888888)
│       │       ├── Workload: ML Platform
│       │       ├── Permission Set: prod-admin (ml-team)
│       │       └── OIDC: GitHub (acme-ml-platform repo)
│       │
│       └── NonProduction
│           ├── Staging
│           │   ├── Account: acme-platform-api-staging (ID: 999999999991)
│           │   │   ├── Permission Set: dev-engineer (acme-platform-api-team)
│           │   │   └── OIDC: GitHub
│           │   │
│           │   ├── Account: acme-data-lake-staging (ID: 999999999992)
│           │   │   ├── Permission Set: dev-engineer (data-team)
│           │   │   └── OIDC: GitHub
│           │   │
│           │   └── Account: acme-ml-platform-staging (ID: 999999999993)
│           │       ├── Permission Set: dev-engineer (ml-team)
│           │       └── OIDC: GitHub
│           │
│           └── Development
│               ├── Account: acme-platform-api-dev (ID: 999999999994)
│               │   └── Permission Set: dev-engineer (acme-platform-api-team)
│               │
│               ├── Account: acme-data-lake-dev (ID: 999999999995)
│               │   └── Permission Set: dev-engineer (data-team)
│               │
│               ├── Account: acme-ml-platform-dev (ID: 999999999996)
│               │   └── Permission Set: dev-engineer (ml-team)
│               │
│               └── Account: sandbox (ID: 999999999997)
│                   └── Permission Set: dev-engineer (all developers)
```

## Permission Sets (Identity Center)

Centrally defined in `aws-infra/terraform/org/identity-center.tf`:

| Permission Set | Policies | Session | Teams |
|---|---|---|---|
| `dev-engineer` | PowerUserAccess | 4h | Dev teams (all non-prod accounts) |
| `prod-read` | ReadOnlyAccess | 1h | Support, on-call engineers, auditors |
| `prod-admin` | AdministratorAccess | 1h | Team owning the account |
| `platform-admin` | AdministratorAccess | 4h | Platform engineering (all accounts) |
| `security-admin` | SecurityAudit, custom inline | 2h | Security team (read-only + audit capability) |

## Identity Center user groups

Organize users by team/responsibility:

```
Identity Center Directory
├── Group: platform-engineers
│   ├── User: alice@company.com (lead)
│   └── User: bob@company.com
│   └── Assigned: platform-admin (all accounts)
│
├── Group: acme-platform-api-team
│   ├── User: charlie@company.com
│   └── User: diana@company.com
│   └── Assigned:
│       ├── To prod account: prod-admin
│       ├── To staging: dev-engineer
│       └── To dev: dev-engineer
│
├── Group: data-team
│   ├── User: eve@company.com
│   └── Assigned:
│       ├── To prod: prod-admin
│       ├── To staging: dev-engineer
│       └── To dev: dev-engineer
│
├── Group: ml-team
│   ├── User: frank@company.com
│   └── Assigned:
│       ├── To prod: prod-admin
│       ├── To staging: dev-engineer
│       └── To dev: dev-engineer
│
├── Group: prod-support
│   ├── User: grace@company.com (on-call)
│   └── Assigned: prod-read (all prod accounts)
│
├── Group: security-team
│   ├── User: henry@company.com
│   └── Assigned: security-admin (all accounts)
│
└── Group: auditors
    ├── User: iris@company.com
    └── Assigned: prod-read (all accounts, read-only)
```

## Repository structure

```
GitHub Organization (UtopikGoodies)
│
├── aws-infra (this repo) — Platform governance
│   ├── terraform/bootstrap — S3 + DynamoDB state backend
│   ├── terraform/org — OUs, SCPs, identity-center, AFT assignments
│   ├── terraform/aft/account-requests — Account request templates
│   └── docs/ — Architecture, SSO, workload strategy
│
├── aws-terraform-modules — Shared IaC library
│   ├── modules/vpc/
│   ├── modules/iam-baseline/
│   ├── modules/observability/
│   ├── modules/rds/
│   └── modules/eks/
│
├── acme-platform-api — Workload repo (Platform API team)
│   ├── terraform/environments/dev/
│   ├── terraform/environments/staging/
│   ├── terraform/environments/prod/
│   ├── terraform/modules/ (app-specific)
│   ├── .github/workflows/ (CI/CD)
│   └── README.md
│
├── acme-data-lake — Workload repo (Data team)
│   ├── terraform/environments/
│   ├── .github/workflows/
│   └── README.md
│
├── acme-ml-platform — Workload repo (ML team)
│   ├── terraform/environments/
│   ├── .github/workflows/
│   └── README.md
│
└── acme-shared-services — Workload repo (Platform team)
    ├── terraform/environments/
    ├── VPC definitions
    ├── DNS setup
    ├── Observability stacks
    └── .github/workflows/
```

## Terraform state structure

```
S3 Bucket: all-terraform-state

s3://all-terraform-state/
├── bootstrap/
│   └── terraform.tfstate (management account only)
│
├── org/
│   └── terraform.tfstate (management account, OUs/SCPs/Identity Center)
│
├── acme-platform-api/
│   ├── dev/us-east-1/terraform.tfstate
│   ├── staging/us-east-1/terraform.tfstate
│   └── prod/us-east-1/terraform.tfstate
│
├── acme-data-lake/
│   ├── dev/eu-west-1/terraform.tfstate
│   ├── staging/eu-west-1/terraform.tfstate
│   └── prod/eu-west-1/terraform.tfstate
│
├── acme-ml-platform/
│   ├── dev/us-west-2/terraform.tfstate
│   ├── staging/us-west-2/terraform.tfstate
│   └── prod/us-west-2/terraform.tfstate
│
└── acme-shared-services/
    ├── prod/us-east-1/terraform.tfstate
    └── prod/eu-west-1/terraform.tfstate
```

## Team responsibilities matrix

| Area | Primary | Secondary | Read-Only |
|------|---------|-----------|-----------|
| AWS Organization (OUs, SCPs) | Platform | — | Security, Auditors |
| Identity Center (permission sets, assignments) | Platform | — | Security |
| State backend (bootstrap) | Platform | — | — |
| Shared services VPC | Platform | Security | All teams |
| Platform API app infrastructure | API team | Platform | — |
| Data Lake app infrastructure | Data team | Platform | Data analysts |
| ML Platform app infrastructure | ML team | Platform | — |
| Cross-account observability | Platform | — | All teams |
| Compliance / auditing | Security | Platform | — |

## Control Tower guardrails

Enable these detective controls (read-only, no enforcement):

```
Recommended guardrails:
├── Elective
│   ├── Disallow deletion of log files in CloudTrail bucket
│   ├── Enable MFA delete on S3 buckets
│   └── Disallow public object ACLs on S3 buckets
│
├── Detective (track, don't block)
│   ├── Detect whether CloudTrail is enabled
│   ├── Detect public RDS database snapshots
│   ├── Detect EC2 instances without required tags
│   └── Detect unencrypted S3 buckets
│
└── Optional (custom via SCPs)
    ├── Deny access to deprecated regions
    ├── Require IMDSv2 on EC2
    └── Require VPC endpoints for S3 access
```

## Onboarding checklist (per new workload team)

**Week 1: Platform team**
- [ ] Create AFT account request for team's prod + staging + dev accounts
- [ ] Define permission sets in Identity Center (or reuse existing)
- [ ] Create GitHub repo for workload
- [ ] Set up GitHub OIDC trust relationships in each account

**Week 2: Workload team**
- [ ] Clone workload repo template
- [ ] Set up Terraform state (point to `all-terraform-state` bucket)
- [ ] Write first infrastructure code (VPC, IAM, app baseline)
- [ ] Test `terraform plan` locally using AWS SSO (`aws sso login --profile dev`)
- [ ] Set up GitHub Actions OIDC + Terraform apply workflow

**Week 3: Ongoing**
- [ ] First PR → review → merge → auto-apply to dev
- [ ] Promote to staging → manual approval
- [ ] Promote to prod → 2 approvals required
- [ ] Monthly access review (remove unused permissions)

## Access flow (example)

**Alice (platform engineer) accessing prod account:**

```
1. Opens VS Code
   ↓
2. Runs: aws sso login --profile prod
   ↓
3. Browser opens → authenticates with company IdP (Okta/Azure AD)
   ↓
4. Identity Center looks up: alice → platform-engineers group → platform-admin permission set
   ↓
5. Temporary AWS credentials returned (valid 4 hours)
   ↓
6. alice@vpc$ terraform apply
   (terraform uses cached credentials automatically)
```

**GitHub Actions (acme-platform-api repo) deploying to prod:**

```
1. Developer: git push to main
   ↓
2. GitHub Actions triggered
   ↓
3. Actions: configure-aws-credentials with OIDC
   ↓
4. AWS STS: validates OIDC token + GitHub repo context
   ↓
5. STS: returns temporary credentials for Github's OIDC role
   ↓
6. Terraform apply (using those credentials)
```

## Key principles

1. **Centralized authority**: Identity Center is the single source of truth for "who can do what"
2. **No static credentials**: Everything uses temporary credentials (SSO or OIDC)
3. **Least privilege**: Start restrictive, grant only what's needed per team/account
4. **Audit-ready**: All actions logged + identity comes from Identity Center / OIDC
5. **Self-service**: New workload teams onboard in ~1 week without ticket requests
6. **Environment parity**: dev/staging/prod configs identical, only data differs
7. **Separation of concerns**: App teams own their infrastructure; platform team owns org

## Success metrics

- ✅ Zero static AWS credentials in GitHub Secrets
- ✅ One place to manage access (Identity Center)
- ✅ New workload team onboarded in < 1 week
- ✅ Per-account state isolated (blast radius = 1 account)
- ✅ Terraform applies automatically to non-prod on merge
- ✅ Prod changes require 2+ approvals + manual trigger
- ✅ Monthly compliance audit runnable in < 1 hour
- ✅ Drift detection runs weekly (alerts if manual changes detected)
