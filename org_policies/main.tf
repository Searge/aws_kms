# Configure AWS Organizations Service Control Policies (SCPs) for root and
# organizational units.
module "scps" {
  source             = "../modules/org_policies"
  policy_type        = "SERVICE_CONTROL_POLICY"
  policies_directory = format("policies/%s", lower(var.policy_type))
  ou_map = {
    "${local.root_id}" = ["mfa-critical-api", "waiting-period"]
    "${local.dev_id}" = [
      "deny_dev_key_access_except_dev_ou",
      "tag_enforcement"
    ]
    "${local.prod_id}" = [
      "deny_prod_key_access_except_prod_ou",
      "tag_enforcement",
      "kms_spec_admin"
    ]
  }
}

# Configure AWS Organizations Resource Control Policies (RCPs) for root and
# organizational units.
module "rcps" {
  source             = "../modules/org_policies"
  policy_type        = "RESOURCE_CONTROL_POLICY"
  policies_directory = format("policies/%s", lower(var.policy_type))
  ou_map = {
    "${local.root_id}" = [
      "ext_principal_protection",
      "svc_principal_protection"
    ]
    "${local.prod_id}" = ["delete_protection"]
  }
}
