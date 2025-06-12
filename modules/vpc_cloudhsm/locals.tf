# Get available AZs if not specified
data "aws_availability_zones" "available" {
  state = "available"
}

# Get current region
data "aws_region" "current" {}

# Get current caller identity
data "aws_caller_identity" "current" {}

locals {
  # Use specified AZs or default to first 2 available
  availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)

  # Calculate subnet CIDRs if not provided
  vpc_cidr_newbits = 24 - parseint(split("/", var.vpc_cidr)[1], 10)

  # Private subnets (starting from .0)
  calculated_private_cidrs = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs : [
    for i in range(length(local.availability_zones)) :
    cidrsubnet(var.vpc_cidr, local.vpc_cidr_newbits, i)
  ]

  # Public subnets (starting from middle of address space)
  calculated_public_cidrs = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs : [
    for i in range(length(local.availability_zones)) :
    cidrsubnet(var.vpc_cidr, local.vpc_cidr_newbits, i + 128)
  ]

  # Cost calculation
  nat_gateway_count          = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(local.availability_zones)) : 0
  estimated_monthly_nat_cost = local.nat_gateway_count * 45.0 # ~$45/month per NAT gateway
  estimated_monthly_eip_cost = local.nat_gateway_count * 3.6  # ~$3.6/month per EIP

  # VPC endpoints cost (interface endpoints only, gateway endpoints are free)
  interface_endpoints_count        = var.create_vpc_endpoints ? 1 : 0      # KMS endpoint
  estimated_monthly_endpoints_cost = local.interface_endpoints_count * 7.2 # ~$7.2/month per interface endpoint

  total_estimated_monthly_cost = local.estimated_monthly_nat_cost + local.estimated_monthly_eip_cost + local.estimated_monthly_endpoints_cost

  # Common tags
  common_tags = merge(var.tags, {
    Environment = var.environment_name
    Module      = "vpc-cloudhsm"
    Purpose     = "CloudHSM networking infrastructure"
  })
}
