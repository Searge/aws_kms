# Locals
# Make variables for organizational units ids
locals {
  root_id = data.aws_organizations_organization.org.roots[0].id
  dev_id  = data.aws_organizations_organizational_unit.list["dev"].id
  prod_id = data.aws_organizations_organizational_unit.list["prod"].id
}
