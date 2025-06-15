###############################################################################
# CloudHSM Cluster Outputs
###############################################################################
output "cluster_id" {
  description = "ID of the CloudHSM cluster"
  value       = try(aws_cloudhsm_v2_cluster.hsm_cluster[0].cluster_id, null)
}

output "cluster_state" {
  description = "State of the CloudHSM cluster"
  value       = try(aws_cloudhsm_v2_cluster.hsm_cluster[0].cluster_state, null)
}

output "cluster_certificates" {
  description = "CloudHSM cluster certificates"
  value = try({
    cluster_certificates = aws_cloudhsm_v2_cluster.hsm_cluster[0].cluster_certificates
  }, null)
  sensitive = true
}

output "security_group_id" {
  description = "ID of the CloudHSM security group"
  value       = try(module.vpc.hsm_cluster_security_group_id, null)
}

###############################################################################
# HSM Instance Outputs
###############################################################################
output "hsm_instance_ids" {
  description = "List of HSM instance IDs"
  value       = try([for hsm in aws_cloudhsm_v2_hsm.hsm_instances : hsm.hsm_id], [])
}

output "hsm_instance_states" {
  description = "List of HSM instance states"
  value       = try([for hsm in aws_cloudhsm_v2_hsm.hsm_instances : hsm.hsm_state], [])
}

output "hsm_availability_zones" {
  description = "Availability zones of HSM instances"
  value       = try([for hsm in aws_cloudhsm_v2_hsm.hsm_instances : hsm.availability_zone], [])
}

###############################################################################
# KMS Custom Key Store Outputs
###############################################################################
output "key_store_id" {
  description = "ID of the KMS custom key store"
  value       = try(aws_kms_custom_key_store.hsm_key_store[0].id, null)
}

output "key_store_name" {
  description = "Name of the KMS custom key store"
  value       = try(aws_kms_custom_key_store.hsm_key_store[0].custom_key_store_name, null)
}

output "key_store_state" {
  description = "State of the KMS custom key store"
  value       = try(aws_kms_custom_key_store.hsm_key_store[0].id, null)
}

###############################################################################
# Network Infrastructure Outputs
###############################################################################
output "vpc_id" {
  description = "ID of the CloudHSM VPC"
  value       = try(module.vpc.vpc_id, null)
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = try(module.vpc.private_subnet_ids, [])
}

output "route_table_id" {
  description = "ID of the private route table"
  value       = try(module.vpc.private_route_table_ids[0], null)
}

###############################################################################
# IAM Role Outputs
###############################################################################
output "hsm_service_role_arn" {
  description = "ARN of the CloudHSM service role"
  value       = try(aws_iam_role.cloudhsm_service_role[0].arn, null)
}

output "hsm_admin_role_arn" {
  description = "ARN of the HSM administration role"
  value       = try(aws_iam_role.hsm_admin_role[0].arn, null)
}

output "kms_integration_role_arn" {
  description = "ARN of the KMS-CloudHSM integration role"
  value       = try(aws_iam_role.kms_hsm_role[0].arn, null)
}

###############################################################################
# Cost and Monitoring Outputs
###############################################################################
output "estimated_monthly_cost_usd" {
  description = "Estimated total monthly cost in USD (HSM + VPC infrastructure)"
  value       = format("%.2f", local.total_estimated_cost)
}

output "cost_breakdown" {
  description = "Detailed cost breakdown"
  value = {
    hsm_instances      = format("$%.2f", local.estimated_hsm_cost)
    vpc_infrastructure = format("$%.2f", local.estimated_vpc_cost)
    total              = format("$%.2f", local.total_estimated_cost)
  }
}

output "cluster_endpoint" {
  description = "CloudHSM cluster endpoint for client connections"
  value       = try(aws_cloudhsm_v2_cluster.hsm_cluster[0].cluster_id, null)
}

output "module_info" {
  description = "Module metadata and configuration summary"
  value = {
    module_version     = "1.0.0"
    environment        = var.environment_name
    hsm_instance_count = var.hsm_instance_count
    hsm_type           = var.hsm_type
    cost_optimized     = var.hsm_type == "hsm1.medium"
    ha_enabled         = var.hsm_instance_count >= 2
    custom_key_store   = var.create_custom_key_store
  }
}
