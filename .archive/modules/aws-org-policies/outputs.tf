output "policy_ids" {
  description = "Map of policy names to their IDs"
  value = {
    for name, policy in aws_organizations_policy.policies : name => policy.id
  }
}

output "policy_arns" {
  description = "Map of policy names to their ARNs"
  value = {
    for name, policy in aws_organizations_policy.policies : name => policy.arn
  }
}

output "policy_content" {
  description = "Map of policy names to their rendered content"
  value = {
    for name, policy in aws_organizations_policy.policies : name => policy.content
  }
}

output "attachment_details" {
  description = "Details about policy attachments"
  value = {
    for key, attachment in aws_organizations_policy_attachment.attachments : key => {
      policy_id = attachment.policy_id
      target_id = attachment.target_id
    }
  }
}
