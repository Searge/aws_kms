# Sentinel Policies for AWS KMS Security

This repository contains Sentinel policies that enforce security and compliance rules for AWS KMS resources deployed with Terraform. Sentinel acts as a policy-as-code framework that ensures infrastructure changes adhere to organizational security requirements before deployment.

## Overview

The Sentinel policies in this repository enforce:

1. **KMS Key Security Baseline** - Ensures all KMS keys are configured securely with:
   - Required tags
   - Automatic key rotation
   - Appropriate deletion window

2. **Organization Policy Types** - Validates policy types used in AWS Organizations

## Policy Details

### KMS Key Security Baseline (`env/dev/ensure-secure-kms-policy.sentinel`)

This policy validates that all KMS keys being created follow security best practices:

```hcl
# Key validations:
# 1. Mandatory tags  : environment, owner, data-classification
# 2. Key rotation    : enable_key_rotation must be true
# 3. Deletion delay  : deletion_window_in_days must be >= 30
```

The policy works by:

- Filtering plan for resources creating AWS KMS keys
- Enforcing required tags on all keys
- Ensuring automatic key rotation is enabled
- Requiring a minimum 30-day deletion waiting period

These rules enhance security by:

- Making keys traceable through proper tagging
- Implementing key rotation as a cryptographic best practice
- Preventing accidental deletion through sufficient waiting periods

### Policy Type Enforcement (`organization/ensure-policy-type.sentinel`)

This policy ensures that only approved policy types are used with AWS Organizations:

```hcl
allowed_policy_types = [
  "AISERVICES_OPT_OUT_POLICY",
  "BACKUP_POLICY",
  "RESOURCE_CONTROL_POLICY",
  "SERVICE_CONTROL_POLICY",
  "TAG_POLICY"
]
```

This is a simpler policy that acts as an example, but may be less critical for organization policies since:

- AWS already enforces valid policy types at the API level
- The Terraform provider includes validation for these values
- Organizations typically have a well-defined governance structure

## CI/CD Integration

These policies are integrated with GitHub Actions in the `.github/workflows/aws_kms_dev.yml` workflow:

1. Terraform generates a plan for review
2. The plan is converted to Sentinel mock format
3. Sentinel tests are executed against the plan
4. Terraform apply proceeds only if all Sentinel policies pass

## Testing

Each policy includes test cases in `pass.hcl` and `fail.hcl` configurations that validate policy behavior:

```txt
sentinel/
├── env/
│   └── dev/
│       ├── ensure-secure-kms-policy.sentinel
│       └── test/
│           └── ensure-secure-kms-policy/
│               ├── fail.hcl  # Tests cases that should be blocked
│               └── pass.hcl  # Tests cases that should be allowed
└── organization/
    ├── ensure-policy-type.sentinel
    └── test/
        └── ensure-policy-type/
            ├── fail.hcl
            └── pass.hcl
```

## Usage

### Local Testing

To test policies locally:

```bash
# Install Sentinel
curl -fsSL https://releases.hashicorp.com/sentinel/0.30.0/sentinel_0.30.0_linux_amd64.zip -o sentinel.zip
unzip sentinel.zip
sudo mv sentinel /usr/local/bin/

# Run tests
cd sentinel
sentinel test
```

### Adding New Policies

When adding a new policy:

1. Create the policy file in the appropriate directory
2. Add test cases in a matching `test/<the policy file name>/` directory
3. Register the policy in `sentinel.hcl` with appropriate enforcement level
4. Ensure CI workflow updates are made if needed

## Enforcement Levels

Policies in `sentinel.hcl` are configured with enforcement levels:

- `hard-mandatory`: Must pass or the Terraform run will fail
- `soft-mandatory`: Can be overridden by authorized users
- `advisory`: Warning only, does not block operations

Both current policies use `hard-mandatory` enforcement, meaning they cannot be overridden.
