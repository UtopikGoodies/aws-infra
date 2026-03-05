output "organization_id" {
  value = data.aws_organizations_organization.current.id
}

output "root_id" {
  value = data.aws_organizations_organization.current.roots[0].id
}

output "organizational_units" {
  value = {
    root_level   = { for key, value in aws_organizations_organizational_unit.root_level : key => value.id }
    second_level = { for key, value in aws_organizations_organizational_unit.second_level : key => value.id }
  }
}

output "accounts" {
  value = { for key, value in aws_organizations_account.accounts : key => value.id }
}
