provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_organizations_organization" "org" {}

# Create the AWS Organization structure
resource "aws_organizations_organizational_unit" "list" {
  for_each  = var.ou_map
  name      = each.key
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

module "scps" {
  source = "../modules/org_policies"
  policy_type = "SERVICE_CONTROL_POLICY"
  ou_map = {
    "r-t32n" = ["root", "allow_services"]
  }
}
module "rcps" {
  source = "../modules/org_policies"
  policy_type = "SERVICE_CONTROL_POLICY"
  ou_map = {
    "r-t32n" = ["root"]
  }
}
