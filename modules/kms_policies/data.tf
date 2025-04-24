data "aws_caller_identity" "current" {}

###############################################################################
# AWS IAM Policy Document
#
# This data creates an IAM policy document that allows the root account
# to administrate a KMS key and allows the SSM and CloudWatch services
# to access the key for encryption and decryption operations.
###############################################################################
data "aws_iam_policy_document" "this" {
  policy_id = "key-policy-ssm-cloudwatch"

  # Root account access - default or with permission delegation prevention
  dynamic "statement" {
    for_each = var.enable_prevent_permission_delegation ? [] : [1]
    content {
      sid = "AllowRootAccountKMSAccess"
      actions = [
        "kms:*",
      ]
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }
      resources = ["*"]
    }
  }

  # Statement preventing permission delegation if enabled
  dynamic "statement" {
    for_each = var.enable_prevent_permission_delegation ? [1] : []
    content {
      sid = "EnableRootAccessAndPreventPermissionDelegation"
      actions = [
        "kms:*",
      ]
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }
      resources = ["*"]
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalType"
        values   = ["Account"]
      }
    }
  }

  # Statement allowing SSM and CloudWatch Logs access
  statement {
    sid = "AllowSSMandCloudWatchLogsAccess"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "logs.amazonaws.com",
        "ssm.amazonaws.com",
      ]
    }
    resources = ["*"]
  }

  # Statement restricting KMS operations to principals from the specified organization
  dynamic "statement" {
    for_each = var.enable_ou_principals_only && var.organization_id != "" ? [1] : []
    content {
      sid = "AllowUseOfTheKMSKeyForOrganization"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:ReEncrypt*",
        "kms:GetKeyPolicy"
      ]
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }
      resources = ["*"]
      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = [var.organization_id]
      }
    }
  }

  # Additional policy statements
  dynamic "statement" {
    for_each = var.additional_policy_statements
    content {
      sid = statement.value.sid
      effect = statement.value.effect
      dynamic "principals" {
        for_each = statement.value.principals
        content {
          type        = principals.key
          identifiers = principals.value
        }
      }
      actions   = statement.value.actions
      resources = statement.value.resources
      dynamic "condition" {
        for_each = statement.value.conditions
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}
