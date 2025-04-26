provider "aws" {
  region = var.aws_region
}

module "kms_keys" {
  source           = "../modules/kms_policies"
  environment_name = var.env
  project          = var.project
  tags             = var.tags

  # Add custom policy for dev environment
  custom_policy    = var.env == "dev" ? file("${path.module}/policies/kms/dev-custom-policy.json") : ""
}
