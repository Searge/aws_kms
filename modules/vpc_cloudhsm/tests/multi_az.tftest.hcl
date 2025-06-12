# Test multi-AZ configuration with different scenarios
run "test_multi_az_with_single_nat" {
  command = plan

  variables {
    environment_name = "test-multi-az"
    vpc_cidr        = "10.88.0.0/16"
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

    # Cost-optimized NAT configuration
    single_nat_gateway = true
    enable_nat_gateway = true
    create_vpc_endpoints = true

    admin_cidr_blocks = ["192.168.1.0/24"]

    tags = {
      owner               = "test"
      environment         = "test"
      data-classification = "internal"
    }
  }

  # Verify 3 AZs create 3 private subnets
  assert {
    condition = length(aws_subnet.private) == 3
    error_message = "Should create 3 private subnets for 3 AZs"
  }

  # Verify single NAT gateway
  assert {
    condition = length(aws_nat_gateway.cloudhsm_nat) == 1
    error_message = "Should create only 1 NAT gateway when single_nat_gateway=true"
  }

  # Verify VPC endpoints are created
  assert {
    condition = var.create_vpc_endpoints ? length(aws_vpc_endpoint.s3) == 1 : true
    error_message = "S3 VPC endpoint should be created when enabled"
  }

  # Verify cost calculation includes NAT gateway
  assert {
    condition = local.estimated_monthly_nat_cost == 45.0
    error_message = "NAT gateway cost should be $45/month for single gateway"
  }
}

run "test_multi_az_with_per_az_nat" {
  command = plan

  variables {
    environment_name = "test-multi-az-ha"
    vpc_cidr        = "10.77.0.0/16"
    availability_zones = ["us-east-1a", "us-east-1b"]

    # High availability NAT configuration
    single_nat_gateway = false
    enable_nat_gateway = true

    tags = {
      owner               = "test"
      environment         = "test"
      data-classification = "internal"
    }
  }

  # Verify per-AZ NAT gateways
  assert {
    condition = length(aws_nat_gateway.cloudhsm_nat) == 2
    error_message = "Should create 2 NAT gateways when single_nat_gateway=false with 2 AZs"
  }

  # Verify cost calculation for multiple NAT gateways
  assert {
    condition = local.estimated_monthly_nat_cost == 90.0
    error_message = "NAT gateway cost should be $90/month for 2 gateways"
  }
}
