provider "aws" {
  region = var.aws_region
}

data "aws_organizations_organization" "org" {}

data "aws_organizations_organizational_unit" "list" {
  for_each  = var.ou_map
  name      = each.key
  parent_id = data.aws_organizations_organization.org.roots[0].id

}

module "scps" {
  source             = "../modules/org_policies"
  policy_type        = "SERVICE_CONTROL_POLICY"
  policies_directory = format("policies/%s", lower(var.policy_type))
  ou_map = {
    "${data.aws_organizations_organization.org.roots[0].id}"        = ["mfa-critical-api", "waiting-period"]
    "${data.aws_organizations_organizational_unit.list["dev"].id}"  = ["env-enforcement", "tag-enforcement"]
    "${data.aws_organizations_organizational_unit.list["prod"].id}" = ["env-enforcement", "tag-enforcement", "kms-spec-admin"]
  }
}

module "rcps" {
  source             = "../modules/org_policies"
  policy_type        = "RESOURCE_CONTROL_POLICY"
  policies_directory = format("policies/%s", lower(var.policy_type))
  ou_map = {
    "${data.aws_organizations_organization.org.roots[0].id}"        = ["ext-principal-protection", "svc-principal-protection"]
    "${data.aws_organizations_organizational_unit.list["prod"].id}" = ["delete-protection"]
  }
}
