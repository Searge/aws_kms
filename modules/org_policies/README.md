# Organization Policies Module

This module will create organization policies in AWS Organizations.

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
| policies\_directory | Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. SPDX-License-Identifier: MIT-0 | `string` | n/a | yes |
| policy\_type | n/a | `string` | `"SERVICE_CONTROL_POLICY"` | no |

## Outputs

| Name | Description |
|------|-------------|
| policies\_directory | Get the policies directory |
| policy\_ids\_debug | Debug policy IDs map |
<!-- END_TF_DOCS -->
