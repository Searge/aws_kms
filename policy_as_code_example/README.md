# AWS KMS Terraform Module with Sentinel Policy-as-Code

## Structure

- `modules/kms_key_policy/`: KMS key module for prod/dev
- `modules/org_policies/`: SCPs to enforce organizational KMS standards
- `examples/`: Usage example of the KMS module
- `sentinel/`: Sentinel policies
- `sentinel.hcl`: Terraform Cloud enforcement config

## Usage

```bash
cd examples
terraform init
terraform apply
```

## Sentinel Policy Checks

The Sentinel policy enforces:

- Required tags
- Valid environment values
- Rotation enabled
- No wildcard `Principal` or `kms:*` actions
- 30-day deletion delay