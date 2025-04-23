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

output "policy_attachments" {
  description = "Map of OUs/accounts with their attached policies"
  value = {
    for ou, _ in merge(module.scps.ou_map, module.rcps.ou_map) : ou => {
      service_control_policies = lookup(module.scps.ou_map, ou, [])
      resource_control_policies = lookup(module.rcps.ou_map, ou, [])
    }
  }
}

output "policy_details" {
  description = "Details of created policies"
  value = {
    service_control_policies = module.scps.policy_ids_debug
    resource_control_policies = module.rcps.policy_ids_debug
  }
}
