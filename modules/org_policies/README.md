<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| org\_policy\_attach | ../org_policy_attach | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_organizations_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ou\_map | n/a | `any` | n/a | yes |
| policies\_directory | Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. SPDX-License-Identifier: MIT-0 | `string` | `"policies"` | no |
| policy\_type | n/a | `string` | `"SERVICE_CONTROL_POLICY"` | no |
<!-- END_TF_DOCS -->