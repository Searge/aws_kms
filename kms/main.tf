provider "aws" {
  region = var.aws_region
}

module "kms_keys" {
  source           = "../modules/kms_policies"
  environment_name = var.env
  project          = var.project
  tags             = var.tags
}
