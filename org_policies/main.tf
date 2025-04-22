# Configure AWS Organizations Service Control Policies (SCPs) for root and
# organizational units.
module "scps" {
  source             = "../modules/org_policies"
  policy_type        = "SERVICE_CONTROL_POLICY"
  policies_directory = format("policies/%s", lower(var.policy_type))
  ou_map = {
    "${local.root_id}" = ["mfa-critical-api", "waiting-period"]
    "${local.dev_id}"  = ["env-enforcement", "tag-enforcement"]
    "${local.prod_id}" = ["env-enforcement", "tag-enforcement", "kms-spec-admin"]
  }
}

# Configure AWS Organizations Resource Control Policies (RCPs) for root and
# organizational units.
module "rcps" {
  source             = "../modules/org_policies"
  policy_type        = "RESOURCE_CONTROL_POLICY"
  policies_directory = format("policies/%s", lower(var.policy_type))
  ou_map = {
    "${local.root_id}" = ["ext-principal-protection", "svc-principal-protection"]
    "${local.prod_id}" = ["delete-protection"]
  }
}
