provider "aws" {
  region = var.aws_region
}

locals {
  # Combine default tags with resource-specific tags
  default_tags = var.default_tags

  # Load built-in policies from files
  kms_tag_enforcement_policy = var.kms_tag_enforcement_enabled ? templatefile("${path.module}/policies/kms/tag-enforcement.json", {
    environment_tags = jsonencode(var.environment_tags)
  }) : null

  kms_waiting_period_policy = var.kms_waiting_period_enabled ? templatefile("${path.module}/policies/kms/waiting-period.json", {
    waiting_period_days = var.kms_deletion_waiting_period_days
  }) : null

  kms_environment_enforcement_policy = var.kms_environment_enforcement_enabled ? templatefile("${path.module}/policies/kms/env-enforcement.json", {
    environment_ou_mapping = jsonencode(var.environment_ou_mapping)
  }) : null

  # Combine built-in policies with user-defined policies
  built_in_policies = {
    kms_tag_enforcement = var.kms_tag_enforcement_enabled ? {
      name        = "${var.naming_prefix}kms-tag-enforcement"
      description = "Enforces tagging standards for KMS keys"
      policy      = local.kms_tag_enforcement_policy
      policy_file = null
      targets     = lookup(var.policy_targets, "kms_tag_enforcement", [])
      tags = merge(local.default_tags, {
        PolicyType = "Compliance"
        Service    = "KMS"
        Purpose    = "TagEnforcement"
      })
    } : null,

    kms_waiting_period = var.kms_waiting_period_enabled ? {
      name        = "${var.naming_prefix}kms-waiting-period"
      description = "Enforces minimum waiting period for KMS key deletion"
      policy      = local.kms_waiting_period_policy
      policy_file = null
      targets     = lookup(var.policy_targets, "kms_waiting_period", [])
      tags = merge(local.default_tags, {
        PolicyType = "Security"
        Service    = "KMS"
        Purpose    = "DeletionControl"
      })
    } : null,

    kms_environment_enforcement = var.kms_environment_enforcement_enabled ? {
      name        = "${var.naming_prefix}kms-environment-enforcement"
      description = "Restricts access to KMS keys based on environment tags and OU structure"
      policy      = local.kms_environment_enforcement_policy
      policy_file = null
      targets     = lookup(var.policy_targets, "kms_environment_enforcement", [])
      tags = merge(local.default_tags, {
        PolicyType = "Security"
        Service    = "KMS"
        Purpose    = "EnvSegregation"
      })
    } : null
  }

  # Filter out null policies
  filtered_built_in_policies = {
    for k, v in local.built_in_policies : k => v if v != null
  }

  # Load policies from files if specified
  file_policies = {
    for k, v in var.org_policies :
    k => merge(v, {
      policy = v.policy_file != null ? file(v.policy_file) : v.policy
    }) if v.policy_file != null
  }

  # Combine all policies
  all_policies = merge(local.filtered_built_in_policies, var.org_policies)
}

# Create the organization policies
resource "aws_organizations_policy" "scp" {
  for_each = local.all_policies

  name        = each.value.name
  description = each.value.description
  content     = each.value.policy
  type        = "SERVICE_CONTROL_POLICY"

  tags = each.value.tags
}

# Attach the policies to targets
resource "aws_organizations_policy_attachment" "attachment" {
  for_each = {
    for policy_target in flatten([
      for policy_key, policy in local.all_policies : [
        for target in policy.targets : {
          policy_key = policy_key
          target_id  = target.target_id
        }
      ]
    ]) : "${policy_target.policy_key}-${policy_target.target_id}" => policy_target
  }

  policy_id = aws_organizations_policy.scp[each.value.policy_key].id
  target_id = each.value.target_id
}
