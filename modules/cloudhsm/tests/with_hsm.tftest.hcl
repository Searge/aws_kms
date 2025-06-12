# Test full CloudHSM deployment (plan only to avoid costs)
run "test_full_cloudhsm_deployment" {
  command = plan

  variables {
    environment_name = "test-hsm"
    vpc_cidr        = "10.77.0.0/16"

    # CloudHSM configuration
    hsm_instance_count = 2
    hsm_type = "hsm1.medium"

    # Network configuration
    availability_zones = ["us-east-1a", "us-east-1b"]
    private_subnet_cidrs = ["10.77.1.0/24", "10.77.2.0/24"]

    # Security configuration
    admin_ssh_cidr_blocks = ["203.0.113.0/24"]

    # KMS integration
    create_custom_key_store = true
    custom_key_store_name = "test-hsm-keystore"

    # Cost optimization for testing
    enable_deletion_protection = false
    enable_hsm_logging = true

    tags = {
      owner               = "CloudHSM Team"
      environment         = "test"
      data-classification = "confidential"
    }
  }

  # Verify CloudHSM cluster is planned
  assert {
    condition = length(aws_cloudhsm_v2_cluster.hsm_cluster) == 1
    error_message = "CloudHSM cluster should be planned when hsm_instance_count > 0"
  }

  # Verify correct number of HSM instances
  assert {
    condition = length(aws_cloudhsm_v2_hsm.hsm_instances) == 2
    error_message = "Should plan 2 HSM instances as specified"
  }

  # Verify KMS custom key store is planned
  assert {
    condition = var.create_custom_key_store ? length(aws_kms_custom_key_store.hsm_key_store) == 1 : true
    error_message = "KMS custom key store should be planned when enabled"
  }

  # Verify IAM roles are planned
  assert {
    condition = length(aws_iam_role.cloudhsm_service_role) == 1
    error_message = "CloudHSM service role should be planned"
  }

  # Verify logging is configured
  assert {
    condition = var.enable_hsm_logging ? length(aws_cloudwatch_log_group.hsm_logs) == 1 : true
    error_message = "CloudWatch log group should be planned when logging enabled"
  }
}
