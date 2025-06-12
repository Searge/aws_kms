# CloudHSM Module Development - Technical Specification

## Objective

Create a Terraform CloudHSM module for AWS KMS Security Framework with educational focus and cost optimization. The module should integrate seamlessly with existing KMS infrastructure while providing hands-on learning experience for AWS key management.

## Architecture Overview

Implement **Option 2**: Separate CloudHSM module with conditional integration into existing KMS module through feature flag.

## Module Structure

```bash
modules/cloudhsm/
├── main.tf          # Core CloudHSM resources
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── iam.tf          # IAM roles and policies
├── vpc.tf          # VPC, subnets, security groups
├── versions.tf     # Provider requirements
├── README.md       # Documentation
└── tests/
    ├── basic.tftest.hcl
    ├── with_hsm.tftest.hcl
    └── cost_optimized.tftest.hcl
```

## Technical Requirements

### 1. Core Resources

- **CloudHSM Cluster**: `aws_cloudhsm_v2_cluster`
- **CloudHSM Instances**: Minimum 2 for HA (different AZs)
- **KMS Custom Key Store**: `aws_kms_custom_key_store`
- **VPC Infrastructure**: Private subnets, route tables, NAT gateway
- **Security Groups**: HSM-specific communication rules

### 2. Security Groups Configuration

```markdown
HSM Cluster SG:
- Inbound: 2223-2225/TCP (HSM communication), 443/TCP (management)
- Outbound: All to VPC CIDR

HSM Management SG:
- Inbound: 22/TCP (admin SSH), 443/TCP (management console)
- Outbound: 443/TCP to internet (AWS APIs)

Client Application SG:
- Outbound: 2223-2225/TCP to HSM cluster
```

### 3. IAM Roles (in iam.tf)

- `cloudhsm_cluster_role` - CloudHSM service role
- `hsm_admin_role` - HSM administration operations
- `hsm_kms_role` - KMS custom key store access

### 4. Cost Optimization Features

- Use `hsm1.medium` (cheapest HSM type)
- Feature flag: `enable_cloudhsm = false` by default
- Optional trust anchor certificate for dev environment
- Lifecycle rules for automatic cleanup in tests

### 5. Integration with Existing KMS Module

Modify `kms/main.tf`:

```hcl
module "cloudhsm" {
  count  = var.enable_cloudhsm ? 1 : 0
  source = "../modules/cloudhsm"
  # variables
}

module "kms_keys" {
  source = "../modules/kms_key"
  custom_key_store_id = var.enable_cloudhsm ? module.cloudhsm[0].key_store_id : null
  # other variables
}
```

### 6. Variables Design

```hcl
# Required
variable "environment_name" { type = string }
variable "vpc_cidr" { type = string, default = "10.1.0.0/16" }

# Optional for learning
variable "trust_anchor_certificate_path" {
  type = string
  default = ""
  description = "Optional for dev environment"
}

# Security
variable "hsm_password_secret_arn" { type = string }
variable "admin_ssh_cidr_blocks" { type = list(string), default = [] }
```

### 7. Terraform Tests

Create comprehensive test suite:

- **basic.tftest.hcl**: VPC and IAM resources only
- **with_hsm.tftest.hcl**: Full CloudHSM deployment
- **cost_optimized.tftest.hcl**: Minimal viable configuration

Tests should include auto-cleanup (destroy) for cost control.

## Key Constraints

- **Educational Focus**: Prioritize learning over production complexity
- **Budget Conscious**: Implement cost controls and warnings
- **Clean Integration**: Keep `kms/` directory minimal - developers only modify `terraform.tfvars`
- **English Only**: All code and comments in English
- **Single File Deliverable**: Create as one comprehensive artifact

## Prerequisites Documentation

Document in README.md:

- HSM user credentials (managed outside Terraform)
- Trust anchor certificate (optional for dev)
- Network planning considerations
- Cost implications and optimization tips

## Success Criteria

1. Module integrates seamlessly with existing KMS infrastructure
2. Simple feature flag enables/disables CloudHSM
3. Comprehensive test coverage with automatic cleanup
4. Clear documentation for educational use
5. Cost-optimized defaults for learning environment
6. All security best practices implemented

Create the complete CloudHSM module following this specification.
