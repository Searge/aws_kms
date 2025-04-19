
output "organization_ids" {
  description = "Get the organization IDs"
  value       = aws_organizations_organization.org.id
}

output "org_accounts" {
  description = "Get the organization accounts"
  value       = aws_organizations_account.org_account
}
