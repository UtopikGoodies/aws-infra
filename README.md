# aws-infra

Control Tower + AFT first baseline for AWS multi-account governance with Infrastructure as Code.

## Operating model (recommended)

- **Control Tower** manages landing zone and governance baseline.
- **AFT** manages account lifecycle through Git-driven workflows.
- This repository stores account request templates and shared IaC conventions.

See [docs/control-tower-aft.md](docs/control-tower-aft.md).

## Prerequisites

- Terraform >= 1.6
- AWS credentials with permissions in the management account
- Existing AWS Organization already created
- AWS Control Tower enabled (recommended)

## Dev Container

This repository includes a VS Code Dev Container at `.devcontainer/devcontainer.json`.

### Start it

1. Open this repository in VS Code.
2. Run: `Dev Containers: Reopen in Container`.
3. Wait for build completion.

The container includes Terraform, AWS CLI, GitHub CLI, and recommended extensions.

### AWS credentials inside container

The devcontainer mounts your host `~/.aws` folder to `/home/vscode/.aws`, so your existing profiles can be used directly:

```bash
aws sts get-caller-identity --profile <your-profile>
```

## How to use this repository

Start here:

1. **New to this repo?** Read [Organization Structure](docs/organization-structure.md) to understand the target setup.
2. **Setting up AWS Control Tower + AFT?** See [Control Tower & AFT](docs/control-tower-aft.md).
3. **Creating workload repositories?** Follow [Workload Repository Strategy](docs/workload-repo-strategy.md).
4. **Using GitHub Codespaces?** See [Codespaces Dotfiles Setup](docs/codespaces-dotfiles.md) to configure your environment.

## Repository structure

- `terraform/bootstrap` — one-time state backend provisioning (S3 + DynamoDB)
- `terraform/aft` — account request templates and AFT scaffolding
- `terraform/org` — legacy org-management stack (migration/compatibility only)
- `docs/` — architecture guides and setup instructions (see "How to use this repository" above)

## Recommended path (Control Tower + AFT)

1. Enable and configure AWS Control Tower in management account.
2. Deploy AFT (Account Factory for Terraform) in your platform tooling account.
3. Use `terraform/aft/account-requests` to define new account requests.
4. Implement account baseline customizations through AFT customization pipelines.

## AFT account request quick start

```bash
cd terraform/aft/account-requests
mkdir nonprod-shared-services
cp template/request.auto.tfvars.json nonprod-shared-services/request.auto.tfvars.json
```

Edit values (name, email, OU, owner fields), then submit via your AFT request pipeline.

## Legacy stack (use only if not on Control Tower yet)

If you are not on Control Tower yet, the legacy Terraform org stack is still available.

### 1) Bootstrap Terraform remote state

From the repository root:

```bash
cd terraform/bootstrap
terraform init
terraform apply \
	-var="state_bucket_name=<globally-unique-bucket-name>" \
	-var="lock_table_name=terraform-state-locks"
```

Save outputs for next step:

- `state_bucket_name`
- `lock_table_name`

### 2) Configure organization model

```bash
cd ../org
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set:

- OU structure in `organizational_units`
- Accounts in `accounts` (unique emails)
- SCPs in `scp_policies`
- Attachments in `policy_attachments`
- Optional delegated admins in `delegated_administrators`

### 3) Initialize org stack with backend config

```bash
terraform init \
	-backend-config="bucket=<state_bucket_name>" \
	-backend-config="key=org/terraform.tfstate" \
	-backend-config="region=<region>" \
	-backend-config="dynamodb_table=<lock_table_name>"
```

### 4) Plan and apply

```bash
terraform plan
terraform apply
```

## Notes and guardrails


- Legacy `terraform/org` stack assumes organization root already exists and reads it as data.
- Legacy OU creation currently supports up to 2 levels:
	- Root -> OU
	- Root -> OU -> OU
- Account creation in AWS Organizations can take several minutes.
- Be careful with SCP rollouts; start with non-production OUs first.

## Suggested next improvements

- Add CI checks (`terraform fmt -check`, `terraform validate`, `terraform plan`)
- Split reusable logic into Terraform modules
- Add account-level baseline stacks (IAM, CloudTrail, Config, Security Hub)