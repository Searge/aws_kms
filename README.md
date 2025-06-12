# AWS KMS Security Framework

A comprehensive Terraform implementation for managing AWS KMS keys with strict security controls following industry regulatory requirements (PCI DSS, NIST) and AWS best practices.

![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.10-blue)
![AWS](https://img.shields.io/badge/AWS-%3E%3D5.94-orange)

## Table of Contents

- [AWS KMS Security Framework](#aws-kms-security-framework)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Key Features](#key-features)
  - [Repository Structure](#repository-structure)
  - [Security Controls Implementation](#security-controls-implementation)
  - [Prerequisites](#prerequisites)
  - [Quick Start](#quick-start)
    - [1. Organization Policies Setup](#1-organization-policies-setup)
    - [2. Environment Key Setup](#2-environment-key-setup)
    - [3. Key Policy Management](#3-key-policy-management)
  - [Module Usage](#module-usage)
    - [KMS Key Module](#kms-key-module)
    - [Organization Policies Module](#organization-policies-module)
  - [Implemented Service Control Policies](#implemented-service-control-policies)
    - [MFA Enforcement for Critical Operations](#mfa-enforcement-for-critical-operations)
    - [Environmental Boundary Enforcement](#environmental-boundary-enforcement)
    - [Key Deletion Protection](#key-deletion-protection)
  - [Sample Key Policies](#sample-key-policies)
    - [Production Environment Key Policy for RDS Encryption](#production-environment-key-policy-for-rds-encryption)
  - [Advanced Usage](#advanced-usage)
    - [CloudHSM Integration](#cloudhsm-integration)
  - [Monitoring and Compliance](#monitoring-and-compliance)
    - [AWS Config Rules](#aws-config-rules)
    - [CloudTrail Monitoring](#cloudtrail-monitoring)
  - [Contributing](#contributing)
  - [References](#references)

## Overview

This framework provides a robust approach to managing AWS KMS encryption keys across multiple environments while enforcing security controls through AWS Organizations policies and strict module configurations. The solution implements:

- Service Control Policies (SCPs) for organization-wide guardrails
- Resource Control Policies (RCPs) for resource-level protections
- Environment-specific key management configurations
- Automated compliance enforcement
- Secure key lifecycle management

## Key Features

- ✅ **Strict Access Controls**: Environment boundary enforcement preventing cross-account misuse
- ✅ **MFA Enforcement**: Requires multi-factor authentication for sensitive key operations
- ✅ **Tag Enforcement**: Mandatory tagging for classification and access control
- ✅ **Key Rotation**: Automatic key rotation enforcement
- ✅ **Deletion Protection**: 30-day minimum deletion window with approval process
- ✅ **Secure CloudHSM Integration**: Support for custom key stores
- ✅ **Audit & Monitoring**: Comprehensive logging and monitoring configuration

## Repository Structure

```txt
.
├── env/                           # Environment-specific configurations
│   ├── dev/                       # Development environment
│   └── prod/                      # Production environment
├── modules/                       # Reusable Terraform modules
│   ├── kms_key/                   # KMS key management module
│   └── org_policies/              # AWS Organizations policy module
├── organization/                  # Organization-level configurations
│   └── ...                        # Organization setup files
├── policies/                      # Policy definitions
│   ├── kms/                       # Key policies
│   └── org/                       # Organization policies
│       ├── resource_control_policy/  # RCPs
│       └── service_control_policy/   # SCPs
└── .gitignore, .tflint.hcl, etc.  # Project configuration files
```

## Security Controls Implementation

This project implements controls aligned with the AWS KMS Policy document, including:

| Control                     | Implementation                               | Policy Reference |
| --------------------------- | -------------------------------------------- | ---------------- |
| Environment Boundaries      | SCPs preventing cross-environment key access | 3.2.2            |
| MFA for Critical Operations | SCP requiring MFA for key management         | 3.2.4            |
| Key Deletion Protection     | 30-day minimum deletion window enforcement   | 3.4.1            |
| Tag-based Access Control    | Resource tagging requirements                | 3.1.1            |
| Automatic Key Rotation      | Enabled by default on all CMKs               | 3.3.1            |
| Administrative Isolation    | Role-based access restrictions               | 3.2.3            |

## Prerequisites

- Terraform ≥ 1.10
- AWS CLI configured with appropriate permissions
- AWS Organization setup with appropriate OUs
- IAM permissions to manage organizations and policies

## Quick Start

### 1. Organization Policies Setup

```bash
cd organization
cp terraform.tfvars.sample terraform.tfvars
# Edit terraform.tfvars with your AWS credentials
terraform init
terraform plan
terraform apply
```

### 2. Environment Key Setup

```bash
# For development environment
cd env/dev
cp terraform.tfvars.sample terraform.tfvars
# Edit terraform.tfvars with your AWS credentials and KMS key configuration
terraform init
terraform plan
terraform apply
```

### 3. Key Policy Management

KMS key policies are defined in the `policies/kms/` directory. To create a new policy:

1. Create a JSON file in the `policies/kms/` directory (e.g., `custom-app-policy.json`)
2. Reference the policy file in your environment's `terraform.tfvars`

## Module Usage

### KMS Key Module

The module implementation is kept clean by defining all configuration values in `terraform.tfvars`:

```hcl
# Module in main.tf
module "kms_keys" {
  source           = "../../modules/kms_key"
  environment_name = var.environment_name
  key_function     = var.key_function
  key_team         = var.key_team
  key_purpose      = var.key_purpose
  description      = var.description
  custom_policy    = var.custom_policy
  enable_key_rotation     = var.enable_key_rotation
  deletion_window_in_days = var.deletion_window_in_days
  tags             = var.tags
}
```

Then in your `terraform.tfvars`:

```hcl
# terraform.tfvars
environment_name = "prod"
key_function     = "db"
key_team         = "payments"
key_purpose      = "encryption"
description      = "KMS key for payment database encryption"
custom_policy    = "prod-payment-policy.json"
enable_key_rotation     = true
deletion_window_in_days = 30

tags = {
  BU              = "Finance"
  BusinessOwner   = "Finance Team"
  TechnicalOwner  = "Database Team"
  ProjectManager  = "Jane Smith"
  Project         = "Payment System"
  Owner           = "Payments Team"
  Environment     = "prod"
}
```

### Organization Policies Module

```hcl
module "scps" {
  source             = "../modules/org_policies"
  policy_type        = "SERVICE_CONTROL_POLICY"
  policies_directory = "../policies/org/service_control_policy"

  ou_map = {
    "${local.root_id}" = ["mfa_critical_api", "waiting_period", "automatic_key_rotation"]
    "${local.dev_id}"  = ["deny_dev_key_access_except_dev_ou", "tag_enforcement"]
    "${local.prod_id}" = ["deny_prod_key_access_except_prod_ou", "tag_enforcement", "kms_spec_admin"]
  }
}
```

## Implemented Service Control Policies

The framework implements several critical SCPs to enforce the security policy:

### MFA Enforcement for Critical Operations

Requires MFA for all sensitive KMS operations:

```json
{
  "Sid": "RequireMFAForCriticalKMSActions",
  "Effect": "Deny",
  "Action": [
    "kms:ScheduleKeyDeletion",
    "kms:DeleteImportedKeyMaterial",
    "kms:DisableKey",
    "kms:PutKeyPolicy",
    "kms:CreateKey"
  ],
  "Resource": "*",
  "Condition": {
    "BoolIfExists": {
      "aws:MultiFactorAuthPresent": "false"
    }
  }
}
```

### Environmental Boundary Enforcement

Prevents cross-environment key access:

```json
{
  "Sid": "DenyDevKeyAccessExceptDevOU",
  "Effect": "Deny",
  "Action": [
    "kms:*"
  ],
  "Resource": "*",
  "Condition": {
    "StringEquals": {
      "aws:ResourceTag/environment": "dev"
    },
    "ForAnyValue:StringNotLike": {
      "aws:PrincipalOrgPaths": "/root/dev/*"
    }
  }
}
```

### Key Deletion Protection

Enforces a minimum 30-day waiting period for key deletion:

```json
{
  "Sid": "EnforceKMSKeyWaitingPeriod",
  "Effect": "Deny",
  "Action": [
    "kms:ScheduleKeyDeletion"
  ],
  "Resource": "*",
  "Condition": {
    "NumericLessThan": {
      "kms:ScheduleKeyDeletionPendingWindowInDays": "30"
    }
  }
}
```

## Sample Key Policies

### Production Environment Key Policy for RDS Encryption

Example key policy for a production RDS database encryption key that follows best practices:

```json
{
  "Version": "2012-10-17",
  "Id": "prod-rds-encryption-key-policy",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow RDS Service to Use the Key",
      "Effect": "Allow",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:DescribeKey"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "rds.us-east-1.amazonaws.com",
          "aws:SourceAccount": "123456789012"
        }
      }
    },
    {
      "Sid": "Allow DB Admin Role to Use the Key",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/prod-db-admin-role"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow Key Administrators",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/prod-kms-admin-role"
      },
      "Action": [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:TagResource",
        "kms:UntagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Restrict Sensitive Operations to MFA",
      "Effect": "Deny",
      "Principal": "*",
      "Action": [
        "kms:ScheduleKeyDeletion",
        "kms:PutKeyPolicy",
        "kms:DisableKey"
      ],
      "Resource": "*",
      "Condition": {
        "BoolIfExists": {
          "aws:MultiFactorAuthPresent": "false"
        }
      }
    },
    {
      "Sid": "DenyKeyUsageFromNonProdOUs",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "kms:*",
      "Resource": "*",
      "Condition": {
        "StringNotLike": {
          "aws:PrincipalOrgPath": "/root/prod/*"
        },
        "Bool": {
          "aws:PrincipalIsAWSService": "false"
        }
      }
    }
  ]
}
```

## Advanced Usage

### CloudHSM Integration

For regulatory requirements that demand FIPS 140-2 Level 3 compliance or hardware-based key material storage, the framework supports AWS CloudHSM integration:

```hcl
# First, create a CloudHSM cluster (if not already existing)
resource "aws_cloudhsm_v2_cluster" "hsm_cluster" {
  hsm_type   = "hsm1.medium"
  subnet_ids = [aws_subnet.hsm_subnet_az1.id, aws_subnet.hsm_subnet_az2.id]
  tags = {
    Name = "prod-cloudhsm-cluster"
  }
}

# Create HSM instances within the cluster (minimum 2 for HA)
resource "aws_cloudhsm_v2_hsm" "hsm_az1" {
  cluster_id = aws_cloudhsm_v2_cluster.hsm_cluster.cluster_id
  subnet_id  = aws_subnet.hsm_subnet_az1.id
}

resource "aws_cloudhsm_v2_hsm" "hsm_az2" {
  cluster_id = aws_cloudhsm_v2_cluster.hsm_cluster.cluster_id
  subnet_id  = aws_subnet.hsm_subnet_az2.id
}

# Configure a custom key store backed by CloudHSM
resource "aws_kms_custom_key_store" "hsm_store" {
  cloud_hsm_cluster_id  = aws_cloudhsm_v2_cluster.hsm_cluster.cluster_id
  custom_key_store_name = "prod-hsm-store"
  key_store_password    = var.hsm_password # Store securely in AWS Secrets Manager
  trust_anchor_certificate = file("${path.module}/certs/customerCA.crt")
}

# Use the custom key store ID in the KMS module
module "kms_keys" {
  source           = "../../modules/kms_key"
  environment_name = var.environment_name
  # Other variables from terraform.tfvars

  # The module references this in locals.tf
  custom_key_store_id = aws_kms_custom_key_store.hsm_store.id
}
```

**Important Notes on CloudHSM:**

1. CloudHSM requires careful network planning with private subnets across multiple AZs
2. Initial setup requires manual configuration of HSM users and trust anchor
3. When using CloudHSM with KMS, automatic key rotation isn't supported and must be implemented manually
4. CloudHSM incurs significant additional costs (per HSM instance per hour)

For more details, see [AWS CloudHSM documentation](https://docs.aws.amazon.com/cloudhsm/latest/userguide/introduction.html) and [KMS Custom Key Store documentation](https://docs.aws.amazon.com/kms/latest/developerguide/custom-key-store-overview.html).

## Monitoring and Compliance

### AWS Config Rules

The framework supports AWS Config managed rules for continuous KMS compliance monitoring. These rules automatically check for non-compliant configurations and can be deployed through AWS Config.

| Rule Name                            | Purpose                                                      | Documentation                                                                                                |
| ------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| `kms-cmk-not-scheduled-for-deletion` | Checks if KMS CMKs are scheduled for deletion                | [AWS Docs](https://docs.aws.amazon.com/config/latest/developerguide/kms-cmk-not-scheduled-for-deletion.html) |
| `kms-key-rotation-enabled`           | Checks if automatic key rotation is enabled for each KMS CMK | [AWS Docs](https://docs.aws.amazon.com/config/latest/developerguide/kms-key-rotation-enabled.html)           |
| `cloud-trail-encryption-enabled`     | Verifies CloudTrail logs are encrypted with KMS              | [AWS Docs](https://docs.aws.amazon.com/config/latest/developerguide/cloud-trail-encryption-enabled.html)     |
| `s3-default-encryption-kms`          | Checks if S3 buckets are encrypted with KMS                  | [AWS Docs](https://docs.aws.amazon.com/config/latest/developerguide/s3-default-encryption-kms.html)          |

Example deployment using Terraform:

```hcl
resource "aws_config_config_rule" "kms_rotation_rule" {
  name        = "kms-key-rotation-enabled"
  description = "Checks whether automatic key rotation is enabled for each KMS key"

  source {
    owner             = "AWS"
    source_identifier = "KMS_CMK_ROTATION_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.config_recorder]
}
```

For detailed guidance on implementing AWS Config with Terraform, see the [Terraform AWS Config documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_config_rule).

### CloudTrail Monitoring

Implementation includes CloudTrail logging for key events that should be monitored:

| Event                        | Severity          | Description                             |
| ---------------------------- | ----------------- | --------------------------------------- |
| `kms:CreateKey`              | Medium            | New key created                         |
| `kms:DisableKey`             | High              | Key disabled, which may impact services |
| `kms:ScheduleKeyDeletion`    | Critical          | Key scheduled for deletion              |
| `kms:PutKeyPolicy`           | High              | Key policy modified                     |
| `kms:EnableKey`              | Medium            | Disabled key re-enabled                 |
| `kms:Decrypt`, `kms:Encrypt` | Low (High Volume) | Normal key usage operations             |

Example CloudWatch Event Rule for detecting key deletion events:

```hcl
resource "aws_cloudwatch_event_rule" "key_deletion_alert" {
  name        = "kms-key-deletion-alert"
  description = "Alert on KMS key deletion scheduling"

  event_pattern = jsonencode({
    source      = ["aws.kms"],
    detail-type = ["AWS API Call via CloudTrail"],
    detail      = {
      eventSource = ["kms.amazonaws.com"],
      eventName   = ["ScheduleKeyDeletion"]
    }
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.key_deletion_alert.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_alerts.arn
}
```

For implementing comprehensive AWS CloudTrail analysis, consider setting up [Amazon Detective](https://aws.amazon.com/detective/) or [Amazon Security Lake](https://aws.amazon.com/security-lake/) which provide advanced security analytics for KMS and other services.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## References

- [AWS KMS Documentation](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html)
- [AWS Organizations SCPs](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [PCI DSS v4.0 Requirements](https://www.pcisecuritystandards.org/)
- [NIST Cryptographic Standards](https://csrc.nist.gov/Projects/Key-Management)
