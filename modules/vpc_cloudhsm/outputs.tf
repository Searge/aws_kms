###############################################################################
# VPC Infrastructure Outputs
###############################################################################
output "vpc_id" {
  description = "ID of the CloudHSM VPC"
  value       = aws_vpc.cloudhsm_vpc.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the CloudHSM VPC"
  value       = aws_vpc.cloudhsm_vpc.cidr_block
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = local.availability_zones
}

output "private_subnet_ids" {
  description = "List of private subnet IDs for CloudHSM deployment"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (for NAT gateways)"
  value       = var.enable_nat_gateway ? aws_subnet.public[*].id : []
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = var.enable_nat_gateway ? aws_subnet.public[*].cidr_block : []
}

###############################################################################
# Network Infrastructure Outputs
###############################################################################
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = var.enable_nat_gateway ? aws_internet_gateway.cloudhsm_igw[0].id : null
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.cloudhsm_nat[*].id
}

output "nat_gateway_eips" {
  description = "List of Elastic IP addresses for NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.private[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = var.enable_nat_gateway ? aws_route_table.public[0].id : null
}

###############################################################################
# Security Group Outputs
###############################################################################
output "hsm_cluster_security_group_id" {
  description = "Security group ID for CloudHSM cluster"
  value       = aws_security_group.hsm_cluster.id
}

output "hsm_management_security_group_id" {
  description = "Security group ID for CloudHSM management (if enabled)"
  value       = var.enable_hsm_management_access ? aws_security_group.hsm_management[0].id : null
}

output "vpc_endpoints_security_group_id" {
  description = "Security group ID for VPC endpoints (if enabled)"
  value       = var.create_vpc_endpoints ? aws_security_group.vpc_endpoints[0].id : null
}

output "default_security_group_id" {
  description = "ID of the default security group (restricted)"
  value       = aws_default_security_group.default.id
}

###############################################################################
# VPC Endpoints Outputs
###############################################################################
output "vpc_endpoint_s3_id" {
  description = "ID of the S3 VPC endpoint"
  value       = var.create_vpc_endpoints ? aws_vpc_endpoint.s3[0].id : null
}

output "vpc_endpoint_dynamodb_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = var.create_vpc_endpoints ? aws_vpc_endpoint.dynamodb[0].id : null
}

output "vpc_endpoint_kms_id" {
  description = "ID of the KMS VPC endpoint"
  value       = var.create_vpc_endpoints ? aws_vpc_endpoint.kms[0].id : null
}

output "vpc_endpoint_logs_id" {
  description = "ID of the CloudWatch Logs VPC endpoint"
  value       = var.create_vpc_endpoints && var.environment_name == "prod" ? aws_vpc_endpoint.logs[0].id : null
}

###############################################################################
# Cost Information Outputs
###############################################################################
output "estimated_monthly_cost_usd" {
  description = "Estimated monthly cost for VPC infrastructure in USD"
  value       = format("%.2f", local.total_estimated_monthly_cost)
}

output "cost_breakdown" {
  description = "Detailed cost breakdown for VPC infrastructure"
  value = {
    nat_gateways              = format("$%.2f", local.estimated_monthly_nat_cost)
    elastic_ips               = format("$%.2f", local.estimated_monthly_eip_cost)
    vpc_endpoints             = format("$%.2f", local.estimated_monthly_endpoints_cost)
    total                     = format("$%.2f", local.total_estimated_monthly_cost)
    nat_gateway_count         = local.nat_gateway_count
    interface_endpoints_count = local.interface_endpoints_count
  }
}

output "cost_optimization_recommendations" {
  description = "Cost optimization recommendations based on current configuration"
  value = {
    nat_gateway_optimization = var.single_nat_gateway ? "✅ Using single NAT gateway for cost optimization" : "💡 Consider single_nat_gateway=true for non-prod environments to reduce costs"

    vpc_endpoints_optimization = var.create_vpc_endpoints ? "✅ VPC endpoints enabled to reduce NAT gateway data transfer costs" : "💡 Enable VPC endpoints to reduce data transfer costs through NAT gateway"

    environment_optimization = var.environment_name != "prod" ? "✅ Non-production environment detected - cost optimizations applied" : "⚠️ Production environment - consider cost vs availability trade-offs"
  }
}

###############################################################################
# Module Metadata Outputs
###############################################################################
output "module_info" {
  description = "Module metadata and configuration summary"
  value = {
    module_name               = "vpc-cloudhsm"
    module_version            = "1.0.0"
    environment               = var.environment_name
    region                    = data.aws_region.current.name
    az_count                  = length(local.availability_zones)
    single_nat_gateway        = var.single_nat_gateway
    vpc_endpoints_enabled     = var.create_vpc_endpoints
    management_access_enabled = var.enable_hsm_management_access
    deployment_date           = timestamp()
  }
}
