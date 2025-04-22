# Data sources
# Get information about the organization
data "aws_organizations_organization" "org" {}

# Get information about the organizational units
data "aws_organizations_organizational_unit" "list" {
  for_each  = var.ou_map
  name      = each.key
  parent_id = data.aws_organizations_organization.org.roots[0].id

}
