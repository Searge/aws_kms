# output "key_id" {
#   description = "The ID of the KMS key"
#   value       = module.kms_keys.key_id
# }

# output "key_arn" {
#   description = "The ARN of the KMS key"
#   value       = module.kms_keys.key_arn
# }

# output "alias_name" {
#   description = "The name of the KMS alias"
#   value       = module.kms_keys.alias_name
# }

# output "alias_arn" {
#   description = "The ARN of the KMS alias"
#   value       = module.kms_keys.alias_arn
# }

# output "account_id" {
#   description = "The AWS account ID"
#   value       = data.aws_caller_identity.current.account_id
# }

# output "environment" {
#   description = "The current environment"
#   value       = var.environment_name
# }
# output "dynamic_statements" {
#   description = "The dynamic policy statements"
#   value       = data.aws_iam_policy_document.this
# }