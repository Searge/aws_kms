provider "aws" {
  region = var.aws_region
}

module "kms_keys" {
  source           = "../modules/kms_policies"
  environment_name = var.env
  project          = var.project
  tags             = var.tags

  # Key alias naming components
  key_function     = var.key_function
  key_team         = var.key_team
  key_purpose      = var.key_purpose

  # Policy selection
  custom_policy    = local.custom_policy
}
