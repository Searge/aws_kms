# Open Policy Agent (OPA) Policies

This directory contains OPA/Rego policies for validating AWS KMS infrastructure configurations.

## What's Inside

- `aws_kms.rego` - Policy rules for KMS key validation
- `README.md` - This documentation

## Policy Rules

The `aws_kms.rego` file enforces three important security rules for KMS keys:

### 1. Required Tags

All KMS keys must have these tags:

- `environment`
- `owner`
- `data-classification`

### 2. Key Rotation

All KMS keys must have automatic key rotation enabled (`enable_key_rotation = true`).

### 3. Deletion Window

All KMS keys must have a deletion window of at least 30 days.

## How to Test

### Using OPA directly

```bash
# Test with OPA command line
opa exec --decision kms/policy --bundle policy plan.json

# Or evaluate specific rules
opa eval -d policy -i plan.json "data.kms.policy.deny"
```

### Using Conftest

```bash
# Test with Conftest (uses package main)
conftest test --policy policy plan.json

# With specific namespace
conftest test --policy policy plan.json --namespace kms.policy

# With detailed output
conftest test -n kms.policy plan.json --output=table
```

## Policy Package

The policy uses package `kms.policy` for OPA and can be used with package `main` for Conftest compatibility.

## Example Output

When a rule fails, you'll see messages like:

```log
KMS key 'module.kms_keys.aws_kms_key.kms_key' is missing required tags: ["owner"]
KMS key 'module.kms_keys.aws_kms_key.kms_key' must have key rotation enabled
KMS key 'module.kms_keys.aws_kms_key.kms_key' deletion window must be at least 30 days, but is set to 7
```

## Integration

These policies can be integrated into:

- CI/CD pipelines with Conftest
- Policy engines with OPA
- Terraform validation workflows
- Infrastructure compliance checks

## Resources

- [Rego Playground](https://play.openpolicyagent.org/)
- [Introduction | Open Policy Agent (OPA)](https://www.openpolicyagent.org/docs)
- [Policy Language | OPA](https://www.openpolicyagent.org/docs/policy-language)
- [Terraform | OPA](https://www.openpolicyagent.org/docs/terraform#goals)
- [Conftest Options](https://www.conftest.dev/options/)
- [Sharing policies](https://www.conftest.dev/sharing/)
- [Terraform OPA policies examples](https://github.com/Scalr/sample-tf-opa-policies/)
- [Infracost policies](https://www.infracost.io/docs/integrations/open_policy_agent/)
