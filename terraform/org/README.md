# Legacy AWS Organizations stack

This stack manages AWS Organizations resources directly with Terraform.

Use this only if you are **not** using Control Tower as the source of truth yet.

If Control Tower is already enabled, avoid managing OUs/accounts/policies here to prevent drift and ownership conflicts.
