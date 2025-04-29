# AWS KMS Policies Module

This module creates AWS KMS keys with customizable policies to implement security best practices for key management.

## Features

- Creates a KMS Customer Master Key (CMK) with configurable policies
- Creates an alias for the CMK
- Supports various policy configurations:
  - Permission delegation prevention
  - Organization-based access restrictions
  - Custom policy statements
  - Complete policy customization

## Usage

```hcl
module "kms_keys" {
  source                           = "../modules/kms_policies"
  environment_name                 = "prod"
  project                          = "my-project"
  enable_prevent_permission_delegation = true
  enable_ou_principals_only        = true
  organization_id                  = "o-xxxxxxxxxxx"
  deletion_window_in_days          = 30
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

## Additional Policy Examples

### Prevent Permission Delegation

This policy ensures that only the account root can perform KMS operations, preventing delegation of permissions:

```hcl
module "kms_keys" {
  source                           = "../modules/kms_policies"
  environment_name                 = "prod"
  project                          = "my-project"
  enable_prevent_permission_delegation = true
  # ... other variables
}
```

### Organization-Based Access Restrictions

This policy restricts key usage to principals within your AWS organization:

```hcl
module "kms_keys" {
  source                    = "../modules/kms_policies"
  environment_name          = "prod"
  project                   = "my-project"
  enable_ou_principals_only = true
  organization_id           = "o-xxxxxxxxxxx"
  # ... other variables
}
```

### Custom Policy Statements

For more complex policies, you can add custom statements:

```hcl
module "kms_keys" {
  source                    = "../modules/kms_policies"
  environment_name          = "prod"
  project                   = "my-project"
  additional_policy_statements = [
    {
      sid       = "AllowRoleToUseKey"
      effect    = "Allow"
      principals = {
        AWS = ["arn:aws:iam::123456789012:role/MyRole"]
      }
      actions   = ["kms:Decrypt", "kms:DescribeKey"]
      resources = ["*"]
      conditions = []
    }
  ]
  # ... other variables
}
```

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
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_policy\_statements | Additional policy statements to include in the KMS key policy | ```list(object({ sid = string effect = string principals = map(list(string)) actions = list(string) resources = list(string) conditions = optional(list(object({ test = string variable = string values = list(string) })), []) }))``` | `[]` | no |
| custom\_policy | Custom policy for the KMS key. If provided, this will replace the default policy | `string` | `""` | no |
| deletion\_window\_in\_days | Duration in days after which the key is deleted after destruction of the resource | `number` | `7` | no |
| enable\_key\_rotation | Enable automatic key rotation | `bool` | `true` | no |
| environment\_name | Environment name for deployment | `string` | n/a | yes |
| key\_function | Function of the KMS key (e.g., db, api) | `string` | `"aws"` | no |
| key\_purpose | Purpose of the KMS key (e.g., encryption, tokenization) | `string` | `"cmk"` | no |
| key\_team | Team responsible for the KMS key (e.g., payments, ml) | `string` | `""` | no |
| policy\_file | Filename for a specific KMS policy file in the policies directory | `string` | `""` | no |
| tags | The map of tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| alias\_arn | The ARN of the KMS alias |
| alias\_name | The name of the KMS alias |
| dynamic\_statements | The dynamic policy statements |
| key\_arn | The ARN of the KMS key |
| key\_id | The ID of the KMS key |
<!-- END_TF_DOCS -->