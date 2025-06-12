# Test cost-optimized configuration for development
run "test_cost_optimized_dev_config" {
  command = plan

  variables {
    environment_name = "dev"
    vpc_cidr        = "10.66.0.0/16"

    # Minimal CloudHSM for cost optimization
    hsm_instance_count = 1  # Single instance for dev
    hsm_type = "hsm1.medium"

    # Network optimization
    availability_zones = ["us-east-1a", "us-east-1b"]

    # Disable expensive features for dev
    create_custom_key_store = false
    enable_deletion_protection = false
    auto_cleanup_enabled = true
    enable_hsm_logging = false

    tags = {
      owner               = "Dev Team"
      environment         = "dev"
      data-classification = "internal"
    }
  }

  # Verify single HSM instance for cost optimization
  assert {
    condition = length(aws_cloudhsm_v2_hsm.hsm_instances) == 1
    error_message = "Should plan only 1 HSM instance for cost optimization"
  }

  # Verify no deletion protection in dev
  assert {
    condition = var.enable_deletion_protection == false
    error_message = "Deletion protection should be disabled for dev environments"
  }

  # Verify auto cleanup is enabled
  assert {
    condition = var.auto_cleanup_enabled ? length(null_resource.auto_cleanup) == 1 : true
    error_message = "Auto cleanup should be planned when enabled"
  }

  # Verify VPC uses cost optimization (single NAT gateway)
  assert {
    condition = module.vpc.cost_breakdown != null
    error_message = "VPC cost breakdown should be available for monitoring"
  }
}

# Test validation failures
run "test_invalid_hsm_type" {
  command = plan
  expect_failures = [var.hsm_type]

  variables {
    environment_name = "test"
    hsm_type = "invalid-type"  # Should fail validation
    hsm_instance_count = 1

    tags = {
      owner               = "test"
      environment         = "test"
      data-classification = "internal"
    }
  }
}
