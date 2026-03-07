# Control Tower + AFT operating model

This repository now assumes **AWS Control Tower** is the authority for landing zone governance, and **AFT (Account Factory for Terraform)** is the authority for account lifecycle through code.

## Ownership boundaries

- Control Tower owns:
  - Landing zone setup
  - Core OUs and guardrail posture
  - Audit and Log Archive account strategy
- AFT owns:
  - Account requests and customization pipelines
  - Per-account baseline Terraform customization
- This repository owns:
  - Account request definitions
  - Shared baseline Terraform code consumed by AFT customizations

## Golden rules

- Control Tower is the source of truth for organization hierarchy.
- Account creation and lifecycle is managed through AFT account requests.
- Per-account customization is handled by AFT customization pipelines.

## Recommended rollout sequence

1. Enable Control Tower in the management account.
2. Configure the target region(s) and baseline guardrails.
3. Deploy AFT according to AWS reference architecture.
4. Move account creation requests into `terraform/aft/account-requests`.
5. Keep account customizations in a dedicated AFT customization repo/pipeline.
