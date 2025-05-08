aws_region            = "us-east-1"

environment_name = "prod"
key_function     = "sign"
key_team         = "security"
key_purpose      = "cmk"

description = "KMS key for signing"

deletion_window_in_days = 7
enable_key_rotation     = true
custom_policy           = "kms-key-policy.json"

tags = {
  data-classification = "internal"
  owner               = "Security Operations"
  environment         = "prod"
}
