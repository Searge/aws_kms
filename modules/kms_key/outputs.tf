output "key_id" {
  description = "The ID of the KMS key"
  value       = aws_kms_key.kms_key
}

output "key_arn" {
  description = "The ARN of the KMS key"
  value       = aws_kms_key.kms_key.arn
}

output "alias_name" {
  description = "The name of the KMS alias"
  value       = aws_kms_alias.key_alias.name
}

output "alias_arn" {
  description = "The ARN of the KMS alias"
  value       = aws_kms_alias.key_alias.arn
}

output "dynamic_statements" {
  description = "The dynamic policy statements"
  value       = data.aws_iam_policy_document.this
}