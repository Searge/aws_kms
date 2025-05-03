aws_region            = "us-east-1"

environment_name = "dev"
key_function     = "sign"
key_team         = "security"
key_purpose      = "maks-7"

description = "KMS key for signing"

deletion_window_in_days = 7
enable_key_rotation     = true
custom_policy           = "kms-key-policy.json"

tags = {
  data-classification = "internal"
  owner               = "Security Operations"
  environment         = "dev"
}
