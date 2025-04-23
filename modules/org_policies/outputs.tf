output "policies_directory" {
  description = "Get the policies directory"
  value       = local.policies_directory
}

output "policy_ids_debug" {
  description = "Debug policy IDs map"
  value       = local.policy_ids
}

output "ou_map" {
  description = "Output of the input OU map"
  value       = var.ou_map
}
