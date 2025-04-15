provider "aws" {
  region = var.aws_region
}

# Get the Organization root
data "aws_organizations_organization" "org" {}

data "aws_organizations_organizational_units" "ou" {
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

# Create OUs for dev and prod environments
resource "aws_organizations_organizational_unit" "dev" {
  name      = "dev"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "prod" {
  name      = "prod"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

# Move Arena account to dev OU
resource "aws_organizations_account" "arena" {
  name      = "arena"
  email     = var.dev_account_email
  parent_id = aws_organizations_organizational_unit.dev.id

  lifecycle {
    ignore_changes = [email, name, role_name]
  }
}

# Move Browbeat account to prod OU
resource "aws_organizations_account" "browbeat" {
  name      = "browbeat"
  email     = var.prod_account_email
  parent_id = aws_organizations_organizational_unit.prod.id

  lifecycle {
    ignore_changes = [email, name, role_name]
  }
}

locals {
  org_root_id = data.aws_organizations_organization.org.roots[0].id

  kms_tag_enforcement_policy = templatefile("${path.module}/${var.tpl_scp_path}/${var.tag_enforcement_policy}", {
    environment_tags = jsonencode(var.environment_tags)
  })

  kms_waiting_period_policy = templatefile("${path.module}/${var.tpl_scp_path}/${var.waiting_period_policy}", {
    waiting_period_days = jsonencode(var.waiting_period_days)
  })

  # Default tags to apply to all resources
  default_tags = {
    ManagedBy  = "Terraform"
    Repository = "infrastructure"
  }
}

#---------------------------------------------------------------
# Service Control Policy for KMS Tag Enforcement
#---------------------------------------------------------------

# Read the policy document from file
data "local_file" "kms_tag_enforcement_policy" {
  filename = "${path.module}/${var.tpl_scp_path}/${var.tag_enforcement_policy}"
}

data "local_file" "kms_waiting_period_policy" {
  filename = "${path.module}/${var.tpl_scp_path}/${var.waiting_period_policy}"
}

# Create the SCP
resource "aws_organizations_policy" "kms_tag_enforcement" {
  name        = "kms-tag-enforcement"
  description = "Enforces tagging standards for KMS keys"
  content     = local.kms_tag_enforcement_policy
  type        = "SERVICE_CONTROL_POLICY"

  tags = merge(local.default_tags, {
    PolicyType = "Compliance"
    Service    = "KMS"
  })
}

resource "aws_organizations_policy" "kms_waiting_period" {
  name        = "kms-waiting-period"
  description = "Enforces minimum waiting period for KMS key deletion"
  content     = local.kms_waiting_period_policy
  type        = "SERVICE_CONTROL_POLICY"

  tags = merge(local.default_tags, {
    PolicyType = "Security"
    Service    = "KMS"
  })
}

# Attach the policy to the root (can be changed to specific OUs later)
resource "aws_organizations_policy_attachment" "kms_tag_attachment" {
  policy_id = aws_organizations_policy.kms_tag_enforcement.id
  target_id = local.org_root_id
}
