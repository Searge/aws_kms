# Test basic VPC creation without CloudHSM-specific features
run "test_basic_vpc_creation" {
  command = plan

  variables {
    environment_name = "test-basic"
    vpc_cidr        = "10.99.0.0/16"
    availability_zones = ["us-east-1a", "us-east-1b"]

    # Minimal configuration
    enable_nat_gateway = false
    create_vpc_endpoints = false
    enable_hsm_management_access = false

    tags = {
      owner               = "test"
      environment         = "test"
      data-classification = "internal"
    }
  }

  # Verify VPC is created
  assert {
    condition = aws_vpc.cloudhsm_vpc.cidr_block == "10.99.0.0/16"
    error_message = "VPC CIDR block should match input"
  }

  # Verify private subnets are created
  assert {
    condition = length(aws_subnet.private) == 2
    error_message = "Should create 2 private subnets for 2 AZs"
  }

  # Verify no NAT gateways created
  assert {
    condition = length(aws_nat_gateway.cloudhsm_nat) == 0
    error_message = "No NAT gateways should be created when disabled"
  }

  # Verify security groups exist
  assert {
    condition = aws_security_group.hsm_cluster.name_prefix == "test-basic-cloudhsm-cluster-"
    error_message = "HSM cluster security group should be created"
  }

  # Verify cost is minimal
  assert {
    condition = local.total_estimated_monthly_cost == 0
    error_message = "Cost should be zero with minimal configuration"
  }
}
