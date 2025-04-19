provider "aws" {
  region = var.aws_region
}

# Data sources
resource "aws_organizations_organization" "org" {}

# Create the AWS Organization structure
resource "aws_organizations_organizational_unit" "list" {
  for_each  = var.ou_map
  name      = each.key
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Create the accounts
resource "aws_organizations_account" "org_account" {
  for_each   = var.accounts_list
  name       = each.value.name
  email      = each.value.email
  role_name  = "RootAdmin"
  parent_id  = aws_organizations_organizational_unit.list[each.key].id
  tags = each.value.tags
}

# module "scps" {
#   source = "../modules/org_policies"
#   policy_type = "SERVICE_CONTROL_POLICY"
#   ou_map = {
#     "r-t32n" = ["root", "allow_services"]
#   }
# }
# module "rcps" {
#   source = "../modules/org_policies"
#   policy_type = "SERVICE_CONTROL_POLICY"
#   ou_map = {
#     "r-t32n" = ["root"]
#   }
# }
