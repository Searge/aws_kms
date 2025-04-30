# Organization Policies

This module provides the ability to create organization policies both for root and organizational units.

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
| rcps | ../modules/org_policies | n/a |
| scps | ../modules/org_policies | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_organizations_organization.org](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_organizations_organizational_unit.list](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organizational_unit) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws\_access\_key\_id | AWS access key ID | `string` | n/a | yes |
| aws\_region | AWS region | `string` | `"us-east-1"` | no |
| aws\_secret\_access\_key | AWS secret access key | `string` | n/a | yes |
| ou\_map | Map of OUs | `map(any)` | ```{ "dev": [ "root" ], "prod": [ "root" ] }``` | no |
| policy\_type | Policy type with validation | `string` | `"SERVICE_CONTROL_POLICY"` | no |

## Outputs

| Name | Description |
|------|-------------|
| ou\_map\_list | Get the ou map list |
| root\_account\_id | Get the root account ID |
<!-- END_TF_DOCS -->
