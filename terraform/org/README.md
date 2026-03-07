# Legacy AWS Organizations stack

This stack manages AWS Organizations resources directly with Terraform.

Use this only if you are **not** using Control Tower as the source of truth yet.

If Control Tower is already enabled, avoid managing OUs/accounts/policies here to prevent drift and ownership conflicts.

## Important prerequisite

By default, this stack expects an AWS Organization to already exist in the management account.

For a brand-new management account, you can set `create_organization = true` in `terraform.tfvars` to have Terraform create the organization.

If you are starting from a brand-new account with no organization yet, follow:

- `docs/from-zero-no-org.md`
