output "organization_id" {
  description = "ID of the AWS organization"
  value       = data.aws_organizations_organization.org.id
}

output "organization_root_id" {
  description = "ID of the organization root"
  value       = data.aws_organizations_organization.org.roots[0].id
}

# Output the list of all direct child OUs under the root
output "child_organizational_units" {
  value = data.aws_organizations_organizational_units.ou.children
}

# Output just the names of the OUs
output "ou_names" {
  value = [for ou in data.aws_organizations_organizational_units.ou.children : ou.name]
}

# Output a map of OU names to their IDs
output "ou_id_map" {
  value = {
    for ou in data.aws_organizations_organizational_units.ou.children :
    ou.name => ou.id
  }
}

# Output detailed information for each OU
output "ou_details" {
  value = {
    for ou in data.aws_organizations_organizational_units.ou.children :
    ou.name => {
      id   = ou.id
      arn  = ou.arn
      path = "/root/${ou.id}"
    }
  }
}

# Outputs for environment OUs
output "dev_ou_id" {
  value = aws_organizations_organizational_unit.dev.id
}

output "prod_ou_id" {
  value = aws_organizations_organizational_unit.prod.id
}

output "account_ou_mapping" {
  value = {
    "arena (dev)"     = aws_organizations_organizational_unit.dev.id
    "browbeat (prod)" = aws_organizations_organizational_unit.prod.id
  }
}

output "kms_tag_enforcement_policy_id" {
  description = "ID of the KMS tag enforcement policy"
  value       = aws_organizations_policy.kms_tag_enforcement.id
}

output "kms_tag_enforcement_policy_arn" {
  description = "ARN of the KMS tag enforcement policy"
  value       = aws_organizations_policy.kms_tag_enforcement.arn
}

output "kms_waiting_period_policy_id" {
  description = "ID of the KMS waiting period policy"
  value       = aws_organizations_policy.kms_waiting_period.id
}
