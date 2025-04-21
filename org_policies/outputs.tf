# Get root account ID
output "root_account_id" {
  description = "Get the root account ID"
  value       = data.aws_organizations_organization.org.roots[0].id
}

# Get ou list
output "ou_map_list" {
  description = "Get the ou map list"
  value       = data.aws_organizations_organizational_unit.list
}
