output "key_id" {
  description = "The ID of the KMS key"
  value       = aws_kms_key.main_cmk.key_id
}

output "key_arn" {
  description = "The ARN of the KMS key"
  value       = aws_kms_key.main_cmk.arn
}

output "alias_name" {
  description = "The name of the KMS alias"
  value       = aws_kms_alias.main_cmk_alias.name
}

output "alias_arn" {
  description = "The ARN of the KMS alias"
  value       = aws_kms_alias.main_cmk_alias.arn
}
