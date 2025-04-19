provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_organizations_organization" "org" {}

# Create the AWS Organization structure
resource "aws_organizations_organizational_unit" "list" {
  for_each  = var.accounts_list
  name      = each.value.name
  parent_id = data.aws_organizations_organization.org.roots[0].id
}


# Create the accounts
resource "aws_organizations_account" "org_account" {
  for_each  = var.accounts_list
  name      = each.value.name
  email     = each.value.email
  parent_id = aws_organizations_organizational_unit.list[each.key].id
}

# Policy definitions with templates
module "org_policies" {
  source = "../modules/aws-org-policies"

  template_dir = "${path.module}/templates"

  policies = {
    # KMS Tag Enforcement Policy
    kms_tag_enforcement = {
      template = "${path.module}/${var.tag_enforcement_policy}"
      vars = {
        allowed_environments = ["dev", "prod"]
      }
      name        = "kms-tag-enforcement"
      description = "Enforces tagging standards for KMS keys"
      type        = "SERVICE_CONTROL_POLICY"
      targets = [
        aws_organizations_organizational_unit.dev.id,
        aws_organizations_organizational_unit.prod.id
      ]
      tags = {
        PolicyType = "Compliance",
        Service    = "KMS"
      }
    },

    # KMS Waiting Period Policy
    kms_waiting_period = {
      template = "${path.module}/${var.waiting_period_policy}"
      vars = {
        waiting_period_days = 30
      }
      name        = "kms-waiting-period"
      description = "Enforces minimum waiting period for KMS key deletion"
      type        = "SERVICE_CONTROL_POLICY"
      targets = [
        data.aws_organizations_organization.org.roots[0].id
      ]
      tags = {
        PolicyType = "Security",
        Service    = "KMS"
      }
    },

    # Dev Environment Enforcement Policy
    dev_env_enforcement = {
      template = "${path.module}/${var.env_enforcement_policy}"
      vars = {
        environment = "dev"
      }
      name        = "dev-env-enforcement"
      description = "Controls access to dev environment KMS resources"
      type        = "SERVICE_CONTROL_POLICY"
      targets = [
        aws_organizations_organizational_unit.dev.id
      ]
      tags = {
        PolicyType  = "Governance",
        Service     = "KMS",
        Environment = "dev"
      }
    },

    # Prod Environment Enforcement Policy
    prod_env_enforcement = {
      template = "${path.module}/${var.env_enforcement_policy}"
      vars = {
        environment = "prod"
      }
      name        = "prod-env-enforcement"
      description = "Controls access to prod environment KMS resources"
      type        = "SERVICE_CONTROL_POLICY"
      targets = [
        aws_organizations_organizational_unit.prod.id
      ]
      tags = {
        PolicyType  = "Governance",
        Service     = "KMS",
        Environment = "prod"
      }
    },

    # KMS Admin Policy for DevOps team
    kms_admin_devops = {
      template = "${path.module}/${var.kms_admin_policy}"
      vars = {
        managed_environments = ["dev", "test"]
      }
      name        = "kms-admin-devops"
      description = "KMS administration permissions for DevOps team"
      type        = "SERVICE_CONTROL_POLICY"
      targets = [
        aws_organizations_organizational_unit.dev.id
      ]
      tags = {
        PolicyType = "Administrative",
        Service    = "KMS",
        Team       = "DevOps"
      }
    },

    # KMS Admin Policy for SRE team
    kms_admin_sre = {
      template = "${path.module}/${var.kms_admin_policy}"
      vars = {
        managed_environments = ["prod"]
      }
      name        = "kms-admin-sre"
      description = "KMS administration permissions for SRE team"
      type        = "SERVICE_CONTROL_POLICY"
      targets = [
        aws_organizations_organizational_unit.prod.id
      ]
      tags = {
        PolicyType = "Administrative",
        Service    = "KMS",
        Team       = "SRE"
      }
    }
  }

  repository_name = "infrastructure"
  service_name    = "AWS"
}
