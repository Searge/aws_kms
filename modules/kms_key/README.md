# AWS KMS Policies Module

This module creates AWS KMS keys with customizable policies to implement security best practices for key management.

## Features

- Creates a KMS Customer Master Key (CMK) with configurable policies
- Creates an alias for the CMK
- Supports various policy configurations:
  - File-based custom policies
  - Dynamic policy generation
  - Additional policy statements
  - Organization-based access restrictions

## Usage

```hcl
module "kms_keys" {
  source           = "../modules/kms_policies"
  environment_name = "prod"
  tags = {
    BU              = "Finance"
    BusinessOwner   = "Jane Doe"
    TechnicalOwner  = "John Smith"
    ProjectManager  = "Alex Johnson"
    Project         = "Security Enhancement"
    Owner           = "Security Team"
    Environment     = "Production"
  }
}
```

## Policy Configuration

The module supports three approaches to policy configuration in order of precedence:

1. **File-based custom policy** - Complete policy file referenced via `policy_file`
2. **Inline custom policy** - Complete policy JSON passed as `custom_policy`
3. **Dynamic policy generation** - Default policy plus `additional_policy_statements`

### File-Based Custom Policy

To use a file-based policy (recommended approach):

```hcl
# In the root module
module "kms_keys" {
  source           = "../modules/kms_policies"
  environment_name = "prod"
  # The policy_file is passed to the module
  policy_file      = var.policy_file
  # Other variables...
}

# In locals.tf of the root module
locals {
  # This handles reading the file content
  policy_file_path = var.policy_file != "" ? "${path.module}/policies/kms/${var.policy_file}" : ""
  custom_policy    = local.policy_file_path != "" ? file(local.policy_file_path) : ""
}

# In terraform.tfvars
policy_file = "prod-custom-policy.json"
```

Your policy file should be stored in `policies/kms/prod-custom-policy.json` and contain a complete KMS policy document.

### Inline Custom Policy

You can also provide a complete policy directly:

```hcl
module "kms_keys" {
  source           = "../modules/kms_policies"
  environment_name = "prod"
  custom_policy    = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EnableRootAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
EOT
}
```

### Dynamic Policy Generation

If no custom policy is provided, the module generates a policy with:

- A default statement allowing SSM and CloudWatch Logs access
- Any additional statements you define:

```hcl
module "kms_keys" {
  source           = "../modules/kms_policies"
  environment_name = "prod"

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
    }
  ]
}
```

## Policy Precedence

The module applies policies in this order:

1. If `custom_policy` is provided (either directly or via `policy_file`), it is used exclusively
2. If no custom policy is provided, the dynamic policy is generated with:
   - The default statement for AWS services (SSM, CloudWatch)
   - Any additional statements specified in `additional_policy_statements`

## Key Naming Convention

Keys follow this naming pattern for their alias: `alias/<env>-<function>-<team>-<purpose>`

Examples:

- `alias/prod-db-payments-encryption`
- `alias/dev-api-ml-tokenization`

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10 |
| aws | ~> 5.94 |

## Providers

| Name | Version |
|------|---------|
| aws | 5.96.0 |

## Resources

| Name | Type |
|------|------|
| [aws_kms_alias.key_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| custom\_policy | Custom policy file | `string` | `""` | no |
| deletion\_window\_in\_days | Duration in days after which the key is deleted after destruction of the resource | `number` | `7` | no |
| description | Description of the KMS key | `string` | n/a | yes |
| enable\_key\_rotation | Enable automatic key rotation | `bool` | `true` | no |
| environment\_name | Environment name for deployment | `string` | n/a | yes |
| key\_function | Function of the KMS key (e.g., db, api) | `string` | `"aws"` | no |
| key\_purpose | Purpose of the KMS key (e.g., encryption, tokenization) | `string` | `"cmk"` | no |
| key\_team | Team responsible for the KMS key (e.g., payments, ml) | `string` | `""` | no |
| tags | The map of tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| alias\_arn | The ARN of the KMS alias |
| alias\_name | The name of the KMS alias |
| key\_arn | The ARN of the KMS key |
| key\_id | The ID of the KMS key |
<!-- END_TF_DOCS -->