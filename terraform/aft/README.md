# AFT workspace

This folder contains Terraform code and account request definitions for **Account Factory for Terraform (AFT)**.

## Structure

- `main.tf`: AFT Terraform configuration
- `variables.tf`: Input variables
- `versions.tf`: Provider and backend configuration
- `account-requests/`: Account request definitions (one folder per account request)

## Account Requests

AFT account requests are defined as JSON files in the `account-requests/` directory.

Each account request should have the structure:
```
account-requests/
├── template/
│   └── request.auto.tfvars.json     # Template for account requests
├── example-account-1/
│   └── request.auto.tfvars.json     # Account request definition
└── example-account-2/
    └── request.auto.tfvars.json     # Account request definition
```

## Deployment

AFT Terraform is automatically deployed as part of the organization stack:

```bash
scripts/deploy.sh
```

To skip AFT deployment:
```bash
scripts/deploy.sh --skip-aft
```

## Notes

- AFT itself is deployed in AWS using AWS-provided patterns and modules separately from this Terraform code.
- This folder manages AFT account request definitions and validation through Terraform.
- Keep account request naming stable to avoid accidental duplication.
- Account requests defined here are processed by the AWS AFT service pipeline.
