output "organization_id" {
  description = "The ID of the organization"
  value       = data.aws_organizations_organization.org.id
}

output "organization_root_id" {
  description = "The ID of the organization root"
  value       = data.aws_organizations_organization.org.roots[0].id
}

# Policy outputs
output "policy_ids" {
  description = "Map of policy names to their IDs"
  value       = module.org_policies.policy_ids
}

output "policy_arns" {
  description = "Map of policy names to their ARNs"
  value       = module.org_policies.policy_arns
}

output "kms_tag_enforcement_policy_id" {
  description = "ID of the KMS tag enforcement policy"
  value       = module.org_policies.policy_ids["kms_tag_enforcement"]
}

output "kms_tag_enforcement_policy_arn" {
  description = "ARN of the KMS tag enforcement policy"
  value       = module.org_policies.policy_arns["kms_tag_enforcement"]
}

output "kms_waiting_period_policy_id" {
  description = "ID of the KMS waiting period policy"
  value       = module.org_policies.policy_ids["kms_waiting_period"]
}
