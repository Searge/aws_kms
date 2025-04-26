# Organization Policies Module

This module will create organization policies in AWS Organizations.

<!-- BEGIN_TF_DOCS -->

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_organizations_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) | resource |
| [aws_organizations_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ou\_map | Map of OUs | `map(any)` | n/a | yes |
| policies\_directory | Policies directory path | `string` | n/a | yes |
| policy\_type | Policy type | `string` | `"SERVICE_CONTROL_POLICY"` | no |

## Outputs

| Name | Description |
|------|-------------|
| ou\_map | Output of the input OU map |
| policies\_directory | Get the policies directory |
| policy\_ids\_debug | Debug policy IDs map |
<!-- END_TF_DOCS -->
