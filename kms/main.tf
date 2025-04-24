provider "aws" {
  region = var.aws_region
}

module "kms_keys" {
  source           = "../modules/kms_policies"
  environment_name = var.env
  project          = var.project

  # Enhanced policy options
  enable_prevent_permission_delegation = var.enable_prevent_permission_delegation
  enable_ou_principals_only            = var.enable_ou_principals_only
  organization_id                      = var.organization_id
  deletion_window_in_days              = var.deletion_window_in_days
  additional_policy_statements         = var.additional_policy_statements

  tags = var.tags
}

data "aws_caller_identity" "current" {}
