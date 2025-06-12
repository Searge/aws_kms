# Test basic module structure without creating actual CloudHSM resources
run "test_basic_module_structure" {
  command = plan

  variables {
    environment_name = "test-basic"
    vpc_cidr        = "10.88.0.0/16"
    hsm_instance_count = 0  # No HSM instances to avoid costs

    # Minimal configuration
    availability_zones = ["us-east-1a", "us-east-1b"]
    enable_deletion_protection = false
    create_custom_key_store = false

    tags = {
      owner               = "test"
      environment         = "test"
      data-classification = "internal"
    }
  }

  # Verify VPC module is called
  assert {
    condition = module.vpc.vpc_id != null
    error_message = "VPC should be created via vpc_cloudhsm module"
  }

  # Verify no CloudHSM resources are planned when instance count is 0
  assert {
    condition = length(aws_cloudhsm_v2_cluster.hsm_cluster) == 0
    error_message = "No CloudHSM cluster should be planned when hsm_instance_count=0"
  }

  # Verify random suffix is generated
  assert {
    condition = random_id.suffix.byte_length == 4
    error_message = "Random suffix should be generated for unique naming"
  }
}
