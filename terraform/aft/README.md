# AFT workspace

This folder contains repository-side assets aligned to **Account Factory for Terraform (AFT)**.

## Structure

- `account-requests/`: account request definitions (one folder per account request)

## Notes

- AFT itself is deployed in AWS using AWS-provided patterns and modules.
- This folder is intentionally minimal and designed to be connected to your AFT pipelines.
- Keep account request naming stable to avoid accidental duplication.
