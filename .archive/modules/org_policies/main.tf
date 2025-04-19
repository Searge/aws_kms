/*
 * AWS Organizations Policies Module
 * Works with organization-specific templates
 */

locals {
  # Process template files into policy configurations
  policy_configs = {
    for policy_name, config in var.policies : policy_name => {
      template_file = "${var.template_dir}/${config.template}"
      template_vars = config.vars
      name          = try(config.name, policy_name)
      description   = try(config.description, "Policy for ${policy_name}")
      type          = try(config.type, "SERVICE_CONTROL_POLICY")
      targets       = try(config.targets, [])
      tags          = try(config.tags, {})
    }
  }

  # Common tags to apply to all policies
  common_tags = {
    ManagedBy  = "Terraform"
    Repository = var.repository_name
    Service    = var.service_name
  }
}

# Create the policies using templatefile
resource "aws_organizations_policy" "policies" {
  for_each = local.policy_configs

  name        = each.value.name
  description = each.value.description
  type        = each.value.type

  # Render the template with its variables
  content = templatefile(
    each.value.template_file,
    each.value.template_vars
  )

  tags = merge(
    local.common_tags,
    each.value.tags
  )
}

# Create policy attachments
resource "aws_organizations_policy_attachment" "attachments" {
  for_each = {
    for idx, attachment in flatten([
      for policy_name, config in local.policy_configs : [
        for target in config.targets : {
          policy_name = policy_name
          target_id   = target
          key         = "${policy_name}-${target}"
        }
      ]
    ]) : attachment.key => attachment
  }

  policy_id = aws_organizations_policy.policies[each.value.policy_name].id
  target_id = each.value.target_id
}

resource "aws_organizations_policy_attachment" "attachments" {
  for_each = zipmap(
    flatten([
      for policy_name, config in local.policy_configs : [
        for target in config.targets : "${policy_name}-${target}"
      ]
    ]),
    flatten([
      for policy_name, config in local.policy_configs : [
        for target in config.targets : {
          policy_id = aws_organizations_policy.policies[policy_name].id
          target_id = target
        }
      ]
    ])
  )

  policy_id = each.value.policy_id
  target_id = each.value.target_id
}
