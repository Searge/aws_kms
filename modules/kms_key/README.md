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
  source           = "../modules/kms_key"
  environment_name = "dev"
  key_function     = "sign"
  key_team         = "security"
  key_purpose      = "cmk"

  description = "KMS key for signing"

  custom_policy = "kms-key-policy.json"

  tags = {
    data-classification = "internal"
    owner               = "Security Operations"
    environment         = "dev"
  }
}
```

## Key Naming Convention

Keys follow this naming pattern for their alias: `alias/<env>-<function>-<team>-<purpose>`

Examples:

- `alias/prod-db-payments-encryption`
- `alias/dev-api-ml-tokenization`

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.10 |
| aws       | ~> 5.94 |

## Providers

| Name | Version |
| ---- | ------- |
| aws  | 5.96.0  |

## Resources

| Name                                                                                                                          | Type        |
| ----------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_kms_alias.key_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias)              | resource    |
| [aws_kms_key.kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key)                    | resource    |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name                       | Description                                                                       | Type          | Default | Required |
| -------------------------- | --------------------------------------------------------------------------------- | ------------- | ------- | :------: |
| account\_id                | ID of aws account                                                                 | `string`      | n/a     |   yes    |
| custom\_policy             | Custom policy file                                                                | `string`      | `""`    |    no    |
| deletion\_window\_in\_days | Duration in days after which the key is deleted after destruction of the resource | `number`      | `7`     |    no    |
| description                | Description of the KMS key                                                        | `string`      | n/a     |   yes    |
| enable\_key\_rotation      | Enable automatic key rotation                                                     | `bool`        | `true`  |    no    |
| environment\_name          | Environment name for deployment                                                   | `string`      | n/a     |   yes    |
| key\_function              | Function of the KMS key (e.g., db, api)                                           | `string`      | `"aws"` |    no    |
| key\_purpose               | Purpose of the KMS key (e.g., encryption, tokenization)                           | `string`      | `"cmk"` |    no    |
| key\_team                  | Team responsible for the KMS key (e.g., payments, ml)                             | `string`      | `""`    |    no    |
| tags                       | The map of tags                                                                   | `map(string)` | `{}`    |    no    |

## Outputs

| Name        | Description               |
| ----------- | ------------------------- |
| alias\_arn  | The ARN of the KMS alias  |
| alias\_name | The name of the KMS alias |
| key\_arn    | The ARN of the KMS key    |
| key\_id     | The ID of the KMS key     |
<!-- END_TF_DOCS -->
