provider "aws" {
  region = var.aws_region
}

module "kms_keys" {
  source           = "../modules/kms_key"
  environment_name = var.environment_name
  tags             = var.tags

  # Key alias naming components
  key_function = var.key_function
  key_team     = var.key_team
  key_purpose  = var.key_purpose

  description = var.description
  account_id = data.aws_caller_identity.current.id
  # Policy selection
  custom_policy = var.custom_policy
}
