output "policy_ids" {
  description = "Map of policy names to policy IDs"
  value       = {
    for k, v in aws_organizations_policy.scp : k => v.id
  }
}

output "policy_arns" {
  description = "Map of policy names to policy ARNs"
  value       = {
    for k, v in aws_organizations_policy.scp : k => v.arn
  }
}

output "policy_attachments" {
  description = "Map of policy attachments"
  value       = {
    for k, v in aws_organizations_policy_attachment.attachment : k => {
      policy_id = v.policy_id
      target_id = v.target_id
    }
  }
}

output "applied_policies" {
  description = "List of all applied policies"
  value       = [
    for k, v in aws_organizations_policy.scp : {
      name        = v.name
      id          = v.id
      description = v.description
      targets     = [
        for attachment_key, attachment in aws_organizations_policy_attachment.attachment :
        attachment.target_id if attachment.policy_id == v.id
      ]
    }
  ]
}
