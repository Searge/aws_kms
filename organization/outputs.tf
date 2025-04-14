output "organization_id" {
  description = "ID of the AWS organization"
  value       = data.aws_organizations_organization.org.id
}

output "organization_root_id" {
  description = "ID of the organization root"
  value       = data.aws_organizations_organization.org.roots[0].id
}

output "kms_tag_enforcement_policy_id" {
  description = "ID of the KMS tag enforcement policy"
  value       = aws_organizations_policy.kms_tag_enforcement.id
}

output "kms_tag_enforcement_policy_arn" {
  description = "ARN of the KMS tag enforcement policy"
  value       = aws_organizations_policy.kms_tag_enforcement.arn
}
