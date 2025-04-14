provider "aws" {
  region = var.aws_region
}

# Get the Organization root
data "aws_organizations_organization" "org" {}

locals {
  org_root_id = data.aws_organizations_organization.org.roots[0].id

  # Default tags to apply to all resources
  default_tags = {
    ManagedBy   = "Terraform"
    Repository  = "infrastructure"
  }
}

#---------------------------------------------------------------
# Service Control Policy for KMS Tag Enforcement
#---------------------------------------------------------------

# Read the policy document from file
data "local_file" "kms_tag_enforcement_policy" {
  filename = "${path.module}/policies/scps/tag-enforcement.json"
}

# Create the SCP
resource "aws_organizations_policy" "kms_tag_enforcement" {
  name        = "kms-tag-enforcement"
  description = "Enforces tagging standards for KMS keys"
  content     = data.local_file.kms_tag_enforcement_policy.content
  type        = "SERVICE_CONTROL_POLICY"

  tags = merge(local.default_tags, {
    PolicyType = "Compliance"
    Service    = "KMS"
  })
}

# Attach the policy to the root (can be changed to specific OUs later)
resource "aws_organizations_policy_attachment" "kms_tag_attachment" {
  policy_id = aws_organizations_policy.kms_tag_enforcement.id
  target_id = local.org_root_id
}
