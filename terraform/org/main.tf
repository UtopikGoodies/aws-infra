data "aws_organizations_organization" "current" {}

locals {
  root_id = data.aws_organizations_organization.current.roots[0].id

  root_level_ous = {
    for key, ou in var.organizational_units :
    key => ou
    if try(ou.parent_ou_key, null) == null
  }

  second_level_ous = {
    for key, ou in var.organizational_units :
    key => ou
    if try(ou.parent_ou_key, null) != null
  }
}

resource "aws_organizations_organizational_unit" "root_level" {
  for_each = local.root_level_ous

  name      = each.value.name
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "second_level" {
  for_each = local.second_level_ous

  name      = each.value.name
  parent_id = aws_organizations_organizational_unit.root_level[each.value.parent_ou_key].id
}

locals {
  all_ou_ids = merge(
    { for key, ou in aws_organizations_organizational_unit.root_level : key => ou.id },
    { for key, ou in aws_organizations_organizational_unit.second_level : key => ou.id }
  )
}

resource "aws_organizations_account" "accounts" {
  for_each = var.accounts

  email                      = each.value.email
  name                       = each.value.name
  parent_id                  = try(local.all_ou_ids[each.value.parent_ou_key], local.root_id)
  role_name                  = each.value.role_name
  iam_user_access_to_billing = each.value.iam_user_access_to_billing
  close_on_deletion          = each.value.close_on_deletion
  tags                       = each.value.tags
}

resource "aws_organizations_policy" "scp" {
  for_each = var.scp_policies

  name        = each.key
  description = each.value.description
  content     = each.value.content
  type        = "SERVICE_CONTROL_POLICY"
  tags        = each.value.tags
}

resource "aws_organizations_policy_attachment" "scp" {
  for_each = var.policy_attachments

  policy_id = aws_organizations_policy.scp[each.value.policy_key].id
  target_id = each.value.target_type == "ROOT" ? local.root_id : each.value.target_type == "OU" ? local.all_ou_ids[each.value.target_key] : aws_organizations_account.accounts[each.value.target_key].id
}

resource "aws_organizations_delegated_administrator" "service_admin" {
  for_each = var.delegated_administrators

  account_id        = aws_organizations_account.accounts[each.value.account_key].id
  service_principal = each.value.service_principal
}
