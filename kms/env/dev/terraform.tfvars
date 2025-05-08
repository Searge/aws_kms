aws_region            = "us-east-1"

environment_name = "dev"
key_function     = "sign"
key_team         = "security"
key_purpose      = "fun"

description = "KMS key for signing"

deletion_window_in_days = 29
enable_key_rotation     = false
custom_policy           = "kms-key-policy.json"

tags = {
  data-classification = "internal"
  owner               = "Security Operations"
  environment         = "dev"
}

