# AWS KMS Keys Management

This module provides AWS KMS key management with enhanced security policies based on AWS best practices.

## Usage

### Development Environment

To deploy KMS keys for the development environment:

```bash
terraform init
terraform plan -out=tf_plan.diff -var-file=env/dev/terraform.tfvars
terraform apply tf_plan.diff
```

### Production Environment

To deploy KMS keys for the production environment:

```bash
terraform init
terraform plan -out=tf_plan.diff -var-file=env/prod/terraform.tfvars
terraform apply tf_plan.diff
```

## Environment-Specific Configuration

The module uses environment-specific configurations from the following files:

- **Development**: `env/dev/terraform.tfvars`
- **Production**: `env/prod/terraform.tfvars`

## Features

This module supports various security features for KMS keys:

1. **Permission Delegation Prevention**: Restricts KMS access to account principals only, preventing delegation of permissions.

2. **Organization-Based Access Control**: Restricts key operations to principals within your AWS organization.

3. **Custom Policy Statements**: Supports additional policy statements for fine-grained access control.

4. **Environment-Specific Policies**: Different security settings for development and production environments.

5. **Key Deletion Protection**: Configurable key deletion window.

## Policy Examples

The module incorporates security best practices from AWS for KMS keys:

- **Prevent Permission Delegation**: Restricts KMS permissions to account principals.
- **Organization-Only Access**: Limits KMS operations to principals within your organization.
- **MFA for Critical Actions**: Requires MFA for critical KMS operations (in production).
- **Extended Deletion Window**: Longer deletion window for production keys.

## Directory Structure

```txt
kms/
├── env/
│   ├── dev/
│   │   ├── terraform.tfvars
│   │   └── .keep
│   └── prod/
│       ├── terraform.tfvars
│       └── .keep
├── main.tf
├── outputs.tf
├── variables.tf
└── versions.tf
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
| aws | 5.95.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| kms\_keys | ../modules/kms_policies | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_policy\_statements | Additional policy statements to include in the KMS key policy | ```list(object({ sid = string effect = string principals = map(list(string)) actions = list(string) resources = list(string) conditions = optional(list(object({ test = string variable = string values = list(string) })), []) }))``` | `[]` | no |
| aws\_access\_key\_id | AWS access key ID | `string` | n/a | yes |
| aws\_region | AWS region | `string` | `"us-east-1"` | no |
| aws\_secret\_access\_key | AWS secret access key | `string` | n/a | yes |
| custom\_policy | Custom policy for the KMS key. If provided, this will replace the default policy | `string` | `""` | no |
| deletion\_window\_in\_days | Duration in days after which the key is deleted after destruction of the resource | `number` | `7` | no |
| enable\_ou\_principals\_only | Enable restricting KMS operations to principals from a specific organization | `bool` | `false` | no |
| enable\_prevent\_permission\_delegation | Enable preventing permission delegation by restricting KMS access to Account principals only | `bool` | `false` | no |
| env | Environment name | `string` | n/a | yes |
| organization\_id | AWS Organization ID for organization-based access restrictions | `string` | `""` | no |
| project | Project name | `string` | `""` | no |
| tags | The map of tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| account\_id | The AWS account ID |
| alias\_arn | The ARN of the KMS alias |
| alias\_name | The name of the KMS alias |
| environment | The current environment |
| key\_arn | The ARN of the KMS key |
| key\_id | The ID of the KMS key |
<!-- END_TF_DOCS -->