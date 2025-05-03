/*
Organizational Policises and Policy Attachments

Recommended Policy Attachments

Root Account (Organization-wide policies):
- MFA for Critical Operations aligns with section 3.2.4
- Key Deletion Waiting Periodaligns with section 3.4.1

Dev OU:
- Environment Boundary aligns with section 3.2.2
- Tag Enforcement aligns with section 3.1.1

Prod OU:
- Environment Boundary aligns with section 3.2.2
- Tag Enforcement aligns with section 3.1.1
- Admin Restrictions aligns with section 3.2.3
- Key Delete Protection aligns with section 3.4.3
*/

# Configure AWS Organizations Service Control Policies (SCPs) for root and
# organizational units.
module "scps" {
  source             = "../modules/org_policies"
  policy_type        = "SERVICE_CONTROL_POLICY"
  policies_directory = "../policies/aws_organization_policies/service_control_policy"

  ou_map = {
    "${local.root_id}" = [
      "RequireMFAForCriticalKMSActions",
      "PreventDisablingKeyRotation",
      "EnforceAutomaticKeyRotation",
      "EnforceKMSKeyWaitingPeriod"
    ]
    "${local.dev_id}" = [
      "DenyDevKeyAccessExceptDevOU",
      "DenyCreateKeyWithoutRequiredTags",
      "DenyInvalidEnvironmentTagValue",
      "DenyRemovalOfRequiredTags"
    ]
    "${local.prod_id}" = [
      "DenyProdKeyAccessExceptProdOU",
      "DenyCreateKeyWithoutRequiredTags",
      "DenyInvalidEnvironmentTagValue",
      "DenyRemovalOfRequiredTags",
      "DenyAccessWithExceptionRole"
    ]
  }
}

# Configure AWS Organizations Resource Control Policies (RCPs) for root and
# organizational units.
module "rcps" {
  source             = "../modules/org_policies"
  policy_type        = "RESOURCE_CONTROL_POLICY"
  policies_directory = "../policies/aws_organization_policies/resource_control_policy"
  ou_map = {
    "${local.root_id}" = [
      "RCPEnforceIdentityPerimeter",
      "RCPEnforceConfusedDeputyProtection"
    ]
    "${local.prod_id}" = ["DenyAccidentalDeletionKMSKey"]
  }
}
