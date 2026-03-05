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

- Do not manage the same OU/account/SCP in both `terraform/org` and Control Tower.
- Use `terraform/org` only for legacy or migration operations.
- Treat Control Tower as source of truth for organization hierarchy.

## Recommended rollout sequence

1. Enable Control Tower in the management account.
2. Configure the target region(s) and baseline guardrails.
3. Deploy AFT according to AWS reference architecture.
4. Move account creation requests into `terraform/aft/account-requests`.
5. Keep account customizations in a dedicated AFT customization repo/pipeline.

## Migration from legacy org Terraform

If this repository previously created OUs/accounts with `terraform/org`:

1. Freeze changes in `terraform/org`.
2. Confirm the current hierarchy in AWS Organizations and Control Tower.
3. Decide each existing account's target OU under Control Tower governance.
4. Import or recreate account requests in AFT.
5. Decommission `terraform/org` operations once migration is complete.
