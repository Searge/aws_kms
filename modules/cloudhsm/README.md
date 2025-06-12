# AWS CloudHSM Terraform Module

A comprehensive Terraform module for deploying AWS CloudHSM infrastructure with integrated KMS custom key store support, designed for educational use and cost optimization.

## 🎯 Overview

This module creates:

- CloudHSM cluster with configurable HA setup
- VPC infrastructure with private subnets
- Security groups optimized for HSM communication
- IAM roles for CloudHSM and KMS integration
- Optional KMS custom key store backed by CloudHSM
- Cost monitoring and optimization features

## 💰 Cost Awareness

**Important**: CloudHSM incurs significant costs (~$1.60/hour per HSM instance = ~$1,152/month for 2 instances)

- Default configuration uses `hsm1.medium` for cost optimization
- Enable `auto_cleanup_enabled` for development environments
- Monitor costs using the `estimated_monthly_cost_usd` output

## 🚀 Quick Start

```hcl
module "cloudhsm" {
  source = "./modules/cloudhsm"

  environment_name = "dev"
  vpc_cidr        = "10.1.0.0/16"

  # Cost optimization for learning
  hsm_instance_count      = 1  # Minimum for dev
  enable_deletion_protection = false

  tags = {
    owner               = "DevOps Team"
    environment         = "dev"
    data-classification = "internal"
    purpose            = "learning"
  }
}
```

## 📋 Prerequisites

Before using this module, ensure you have:

1. **AWS Credentials**: Appropriate IAM permissions for CloudHSM
2. **Network Planning**: Understand VPC/subnet requirements
3. **Cost Awareness**: CloudHSM billing implications
4. **Certificate Management**: Trust anchor certificate (if using custom key store)

## 🔧 Module Integration

This module integrates with the existing KMS module through a feature flag:

```hcl
# In kms/main.tf
module "cloudhsm" {
  count  = var.enable_cloudhsm ? 1 : 0
  source = "../modules/cloudhsm"
  # ... configuration
}

module "kms_keys" {
  source = "../modules/kms_key"
  custom_key_store_id = var.enable_cloudhsm ? module.cloudhsm[0].key_store_id : null
  # ... other variables
}
```

## 📊 Outputs

Key outputs include:

- `cluster_id`: CloudHSM cluster identifier
- `key_store_id`: KMS custom key store ID
- `estimated_monthly_cost_usd`: Cost estimation
- `hsm_instance_ids`: List of HSM instance IDs

---

*This module is designed for educational purposes with cost optimization in mind. Always review AWS pricing before deployment.*
