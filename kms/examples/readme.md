# AWS KMS Policy Strategies

This document outlines different strategies for configuring secure KMS keys and policies in AWS environments, following best practices for security and compliance.

## Table of Contents

- [AWS KMS Policy Strategies](#aws-kms-policy-strategies)
  - [Table of Contents](#table-of-contents)
  - [Basic KMS Key Setup](#basic-kms-key-setup)
  - [Administrative Access Control](#administrative-access-control)
  - [MFA Enforcement for Critical Operations](#mfa-enforcement-for-critical-operations)
  - [Organization-Based Access Control](#organization-based-access-control)
  - [Environment Isolation](#environment-isolation)
  - [Service-Specific Access Patterns](#service-specific-access-patterns)
  - [Cross-Account Access Strategies](#cross-account-access-strategies)
  - [Custom Key Policies](#custom-key-policies)
    - [File-Based Policy Approach](#file-based-policy-approach)
    - [Policy Precedence](#policy-precedence)
  - [Combining Multiple Strategies](#combining-multiple-strategies)
  - [Implementation Examples](#implementation-examples)
    - [Development Environment](#development-environment)
    - [Production Environment](#production-environment)
    - [Security Compliance Environment](#security-compliance-environment)

## Basic KMS Key Setup

The foundation of any KMS strategy starts with a properly configured key.

```hcl
module "kms_keys" {
  source           = "../modules/kms_policies"
  environment_name = "dev"
  tags = {
    BU              = "Engineering"
    BusinessOwner   = "John Doe"
    TechnicalOwner  = "Jane Smith"
    ProjectManager  = "Alex Johnson"
    Project         = "Core Infrastructure"
    Owner           = "Platform Team"
    Environment     = "Development"
  }

  # Basic key configuration
  enable_key_rotation  = true
  deletion_window_in_days = 7
}
```

This configuration:

- Creates a KMS key with a default alias format
- Enables automatic key rotation
- Sets a 7-day deletion window
- Applies standard tags for governance

## Administrative Access Control

Control who can administer your KMS keys with explicit permissions.

```hcl
additional_policy_statements = [
  {
    sid    = "AllowAdminRoleToDelegatePermissions"
    effect = "Allow"
    principals = {
      AWS = ["arn:aws:iam::*:role/KMSAdminRole"]
    }
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource"
    ]
    resources = ["*"]
  }
]
```

This configuration:

- Restricts administrative actions to a specific IAM role
- Provides granular control over administrative permissions

## MFA Enforcement for Critical Operations

Enhance security by requiring MFA for high-risk operations.

```hcl
additional_policy_statements = [
  {
    sid    = "RequireMFAForCriticalActions"
    effect = "Deny"
    principals = {
      AWS = ["*"]
    }
    actions = [
      "kms:ScheduleKeyDeletion",
      "kms:DeleteImportedKeyMaterial",
      "kms:DisableKey",
      "kms:PutKeyPolicy"
    ]
    resources = ["*"]
    conditions = [
      {
        test     = "BoolIfExists"
        variable = "aws:MultiFactorAuthPresent"
        values   = ["false"]
      }
    ]
  }
]
```

This configuration:

- Denies critical operations unless MFA is present
- Protects against accidental or malicious key deletions
- Adds an extra layer of security for policy changes

## Organization-Based Access Control

Restrict key usage to principals within your AWS organization.

```hcl
additional_policy_statements = [
  {
    sid    = "RestrictToOrganization"
    effect = "Deny"
    principals = {
      AWS = ["*"]
    }
    actions = [
      "kms:*"
    ]
    resources = ["*"]
    conditions = [
      {
        test     = "StringNotEquals"
        variable = "aws:PrincipalOrgID"
        values   = ["o-YOUR_ORG_ID"]
      }
    ]
  }
]
```

This configuration:

- Limits key usage to principals within your organization
- Prevents external entities from using your keys
- Supports a defense-in-depth approach

## Environment Isolation

Keep your development and production environments strictly separated.

```hcl
# For dev keys
additional_policy_statements = [
  {
    sid    = "DenyProdAccess"
    effect = "Deny"
    principals = {
      AWS = ["*"]
    }
    actions = ["kms:*"]
    resources = ["*"]
    conditions = [
      {
        test     = "StringEquals"
        variable = "aws:PrincipalTag/Environment"
        values   = ["prod"]
      }
    ]
  }
]

# For prod keys
additional_policy_statements = [
  {
    sid    = "DenyDevAccess"
    effect = "Deny"
    principals = {
      AWS = ["*"]
    }
    actions = ["kms:*"]
    resources = ["*"]
    conditions = [
      {
        test     = "StringEquals"
        variable = "aws:PrincipalTag/Environment"
        values   = ["dev"]
      }
    ]
  }
]
```

This configuration:

- Ensures development resources cannot access production keys
- Ensures production resources cannot access development keys
- Uses IAM tags to enforce the separation

## Service-Specific Access Patterns

Configure policies for specific AWS services that need to use your KMS keys.

```hcl
additional_policy_statements = [
  {
    sid    = "AllowS3BucketEncryption"
    effect = "Allow"
    principals = {
      Service = ["s3.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    conditions = [
      {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["s3.us-east-1.amazonaws.com"]
      },
      {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:s3:arn"
        values   = ["arn:aws:s3:::my-bucket*"]
      }
    ]
  }
]
```

This configuration:

- Allows S3 to use the key for specific buckets
- Restricts usage to a specific region
- Uses encryption context to further limit scope

## Cross-Account Access Strategies

Safely allow access to your KMS keys from other AWS accounts.

```hcl
additional_policy_statements = [
  {
    sid    = "AllowCrossAccountAccess"
    effect = "Allow"
    principals = {
      AWS = ["arn:aws:iam::123456789012:root"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    conditions = [
      {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = ["o-YOUR_ORG_ID"]
      }
    ]
  }
]
```

This configuration:

- Grants specific permissions to another account
- Ensures the account is part of your organization
- Limits the allowed operations to encryption/decryption

## Custom Key Policies

For advanced scenarios, use a custom policy file stored in a dedicated directory. This approach allows you to maintain policies outside your Terraform code and reuse them across different environments.

### File-Based Policy Approach

Store your KMS policies in a dedicated policy directory:

```txt
kms/
├── policies/
│   ├── kms/
│   │   ├── dev-custom-policy.json
│   │   ├── prod-custom-policy.json
│   │   ├── pci-compliance-policy.json
│   │   └── ...
```

Then reference these policy files in your Terraform variables:

```hcl
# In kms/env/dev/terraform.tfvars
policy_file = "dev-custom-policy.json"

# In kms/env/prod/terraform.tfvars
policy_file = "prod-custom-policy.json"
```

The flow for handling policy files works as follows:

1. In the root module (`kms/main.tf`), you define:

   ```hcl
   module "kms_keys" {
     source           = "../modules/kms_policies"
     environment_name = var.environment_name
     tags             = var.tags
     key_function     = var.key_function
     key_team         = var.key_team
     key_purpose      = var.key_purpose

     # Pass the custom policy content
     custom_policy    = local.custom_policy
   }
   ```

2. The root module's locals (`kms/locals.tf`) reads the policy file:

   ```hcl
   locals {
     # Determine policy file to use
     policy_file_path = var.policy_file != "" ? "${path.module}/policies/kms/${var.policy_file}" : ""
     custom_policy    = local.policy_file_path != "" ? file(local.policy_file_path) : ""
   }
   ```

3. The KMS module then uses the custom policy if provided:

   ```hcl
   resource "aws_kms_key" "kms_key" {
     # ...
     policy = var.custom_policy != "" ? var.custom_policy : data.aws_iam_policy_document.this.json
     # ...
   }
   ```

### Policy Precedence

The module applies policies in this order:

1. If `custom_policy` is specified (via `policy_file`), it will be used exclusively
2. If no custom policy is provided, the default policy will be used:
   - Basic permission for AWS services (SSM, CloudWatch)
   - Plus any `additional_policy_statements` you define

This approach:

- Keeps policies as separate files for better organization
- Allows environment-specific policies
- Supports full policy customization when needed
- Falls back to a sensible default with additional statements

## Combining Multiple Strategies

For comprehensive security, combine multiple strategies.

```hcl
module "kms_keys" {
  source                       = "../modules/kms_policies"
  environment_name             = "prod"
  key_function                 = "db"
  key_team                     = "payments"
  key_purpose                  = "encryption"
  enable_key_rotation          = true
  deletion_window_in_days      = 30

  additional_policy_statements = [
    {
      sid    = "AllowAdminRole"
      effect = "Allow"
      principals = {
        AWS = ["arn:aws:iam::*:role/KMSAdminRole"]
      }
      actions = [
        "kms:Create*", "kms:Describe*", "kms:Enable*",
        "kms:List*", "kms:Put*", "kms:Update*",
        "kms:Revoke*", "kms:Disable*", "kms:Get*",
        "kms:Delete*", "kms:TagResource", "kms:UntagResource"
      ]
      resources = ["*"]
      conditions = [
        {
          test     = "StringEquals"
          variable = "aws:PrincipalOrgID"
          values   = ["o-YOUR_ORG_ID"]
        }
      ]
    },
    {
      sid    = "RequireMFA"
      effect = "Deny"
      principals = {
        AWS = ["*"]
      }
      actions = [
        "kms:ScheduleKeyDeletion",
        "kms:DeleteImportedKeyMaterial",
        "kms:DisableKey",
        "kms:PutKeyPolicy"
      ]
      resources = ["*"]
      conditions = [
        {
          test     = "BoolIfExists"
          variable = "aws:MultiFactorAuthPresent"
          values   = ["false"]
        }
      ]
    },
    {
      sid    = "AllowRDSService"
      effect = "Allow"
      principals = {
        Service = ["rds.amazonaws.com"]
      }
      actions = [
        "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
        "kms:GenerateDataKey*", "kms:DescribeKey"
      ]
      resources = ["*"]
      conditions = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["rds.us-east-1.amazonaws.com"]
        }
      ]
    }
  ]
  tags = {
    BU              = "Finance"
    BusinessOwner   = "CFO"
    TechnicalOwner  = "Database Team"
    ProjectManager  = "Payment Platform PM"
    Project         = "Payment Processing"
    Owner           = "Database Team"
    Environment     = "Production"
  }
}
```

This configuration combines:

- Administrative access control
- MFA enforcement
- Service-specific patterns (RDS)
- Detailed tagging

## Implementation Examples

### Development Environment

For development environments, prioritize flexibility while maintaining basic security guardrails.

```hcl
module "dev_kms_key" {
  source           = "../modules/kms_policies"
  environment_name = "dev"
  key_function     = "api"
  key_team         = "ml"
  key_purpose      = "tokenization"

  deletion_window_in_days = 7

  additional_policy_statements = [
    {
      sid    = "AllowDevelopers"
      effect = "Allow"
      principals = {
        AWS = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Developer"]
      }
      actions = [
        "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
        "kms:GenerateDataKey*", "kms:DescribeKey"
      ]
      resources = ["*"]
    }
  ]

  tags = {
    BU              = "Engineering"
    BusinessOwner   = "CTO"
    TechnicalOwner  = "ML Team Lead"
    ProjectManager  = "AI Platform PM"
    Project         = "ML Platform"
    Owner           = "ML Team"
    Environment     = "Development"
  }
}
```

### Production Environment

For production, implement strict security controls and extended retention periods.

```hcl
module "prod_kms_key" {
  source           = "../modules/kms_policies"
  environment_name = "prod"
  key_function     = "db"
  key_team         = "payments"
  key_purpose      = "encryption"

  deletion_window_in_days = 30

  additional_policy_statements = [
    {
      sid    = "AllowAdminRole"
      effect = "Allow"
      principals = {
        AWS = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/KMSAdminRole"]
      }
      actions = [
        "kms:Create*", "kms:Describe*", "kms:Enable*",
        "kms:List*", "kms:Put*", "kms:Update*",
        "kms:Revoke*", "kms:Disable*", "kms:Get*",
        "kms:Delete*", "kms:TagResource", "kms:UntagResource"
      ]
      resources = ["*"]
    },
    {
      sid    = "RequireMFA"
      effect = "Deny"
      principals = {
        AWS = ["*"]
      }
      actions = [
        "kms:ScheduleKeyDeletion",
        "kms:DeleteImportedKeyMaterial",
        "kms:DisableKey",
        "kms:PutKeyPolicy"
      ]
      resources = ["*"]
      conditions = [
        {
          test     = "BoolIfExists"
          variable = "aws:MultiFactorAuthPresent"
          values   = ["false"]
        }
      ]
    },
    {
      sid    = "RestrictToOrganization"
      effect = "Deny"
      principals = {
        AWS = ["*"]
      }
      actions = ["kms:*"]
      resources = ["*"]
      conditions = [
        {
          test     = "StringNotEquals"
          variable = "aws:PrincipalOrgID"
          values   = ["o-YOUR_ORG_ID"]
        },
        {
          test     = "BoolIfExists"
          variable = "aws:PrincipalIsAWSService"
          values   = ["false"]
        }
      ]
    }
  ]

  tags = {
    BU              = "Finance"
    BusinessOwner   = "CFO"
    TechnicalOwner  = "Security Lead"
    ProjectManager  = "Payment Platform PM"
    Project         = "Payment Processing"
    Owner           = "Security Team"
    Environment     = "Production"
  }
}
```

### Security Compliance Environment

For highly regulated environments that need to meet specific compliance requirements.

```hcl
module "compliance_kms_key" {
  source           = "../modules/kms_policies"
  environment_name = "prod"
  key_function     = "pci"
  key_team         = "compliance"
  key_purpose      = "encryption"

  deletion_window_in_days = 30

  additional_policy_statements = [
    {
      sid    = "AllowComplianceTeam"
      effect = "Allow"
      principals = {
        AWS = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ComplianceOfficer"]
      }
      actions = [
        "kms:Describe*",
        "kms:List*",
        "kms:Get*"
      ]
      resources = ["*"]
    },
    {
      sid    = "RequireMFAForAllOperations"
      effect = "Deny"
      principals = {
        AWS = ["*"]
      }
      actions = ["kms:*"]
      resources = ["*"]
      conditions = [
        {
          test     = "BoolIfExists"
          variable = "aws:MultiFactorAuthPresent"
          values   = ["false"]
        }
      ]
    },
    {
      sid    = "AllowCloudTrailLogs"
      effect = "Allow"
      principals = {
        Service = ["cloudtrail.amazonaws.com"]
      }
      actions = [
        "kms:GenerateDataKey*"
      ]
      resources = ["*"]
      conditions = [
        {
          test     = "StringLike"
          variable = "kms:EncryptionContext:aws:cloudtrail:arn"
          values   = ["arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"]
        }
      ]
    },
    {
      sid    = "RestrictToOrganization"
      effect = "Deny"
      principals = {
        AWS = ["*"]
      }
      actions = ["kms:*"]
      resources = ["*"]
      conditions = [
        {
          test     = "StringNotEquals"
          variable = "aws:PrincipalOrgID"
          values   = ["o-YOUR_ORG_ID"]
        },
        {
          test     = "BoolIfExists"
          variable = "aws:PrincipalIsAWSService"
          values   = ["false"]
        }
      ]
    }
  ]

  tags = {
    BU              = "Compliance"
    BusinessOwner   = "CISO"
    TechnicalOwner  = "Security Operations"
    ProjectManager  = "Compliance PM"
    Project         = "PCI Compliance"
    Owner           = "Security Team"
    Environment     = "Production"
    Compliance      = "PCI-DSS"
  }
}
```
