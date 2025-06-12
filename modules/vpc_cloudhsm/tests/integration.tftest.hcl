# Test full integration scenario simulating CloudHSM module consumption
run "test_cloudhsm_integration_scenario" {
  command = plan

  variables {
    environment_name = "test-integration"
    vpc_cidr        = "10.66.0.0/16"

    # Explicit subnet configuration
    availability_zones    = ["us-east-1a", "us-east-1b"]
    private_subnet_cidrs = ["10.66.1.0/24", "10.66.2.0/24"]
    public_subnet_cidrs  = ["10.66.101.0/24", "10.66.102.0/24"]

    # Full CloudHSM configuration
    admin_cidr_blocks = ["203.0.113.0/24"]
    enable_hsm_management_access = true
    single_nat_gateway = true
    create_vpc_endpoints = true

    tags = {
      owner               = "CloudHSM Team"
      environment         = "test-integration"
      data-classification = "confidential"
    }
  }

  # Verify private subnets use explicit CIDRs
  assert {
    condition = aws_subnet.private[0].cidr_block == "10.66.1.0/24"
    error_message = "First private subnet should use explicit CIDR"
  }

  assert {
    condition = aws_subnet.private[1].cidr_block == "10.66.2.0/24"
    error_message = "Second private subnet should use explicit CIDR"
  }

  # Verify management security group is created
  assert {
    condition = var.enable_hsm_management_access ? length(aws_security_group.hsm_management) == 1 : true
    error_message = "Management security group should be created when enabled"
  }

  # Verify HSM cluster security group has correct ingress rules
  assert {
    condition = contains([
      for rule in aws_security_group.hsm_cluster.ingress :
      rule.from_port == 2223 && rule.to_port == 2225 && rule.protocol == "tcp"
    ], true)
    error_message = "HSM cluster SG should allow CloudHSM ports 2223-2225"
  }

  # Verify outputs needed for CloudHSM integration
  assert {
    condition = length(output.private_subnet_ids) == 2
    error_message = "Should output 2 private subnet IDs for CloudHSM cluster"
  }

  assert {
    condition = output.hsm_cluster_security_group_id != null
    error_message = "Should output HSM cluster security group ID"
  }

  # Verify cost optimization recommendations
  assert {
    condition = can(output.cost_optimization_recommendations.nat_gateway_optimization)
    error_message = "Should provide NAT gateway optimization recommendations"
  }
}

# Test validation rules
run "test_validation_failures" {
  command = plan
  expect_failures = [var.availability_zones]

  variables {
    environment_name = "test-validation"
    availability_zones = ["us-east-1a"]  # Only 1 AZ - should fail validation

    tags = {
      owner               = "test"
      environment         = "test"
      data-classification = "internal"
    }
  }
}

run "test_invalid_cidr" {
  command = plan
  expect_failures = [var.vpc_cidr]

  variables {
    environment_name = "test-validation"
    vpc_cidr = "invalid-cidr"  # Invalid CIDR - should fail validation

    tags = {
      owner               = "test"
      environment         = "test"
      data-classification = "internal"
    }
  }
}

run "test_missing_required_tags" {
  command = plan
  expect_failures = [var.tags]

  variables {
    environment_name = "test-validation"
    availability_zones = ["us-east-1a", "us-east-1b"]

    tags = {
      owner = "test"
      # Missing environment and data-classification - should fail validation
    }
  }
}
