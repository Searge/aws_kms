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

  # Example policy Statement allowing SSM and CloudWatch Logs access
  # If you need to add more statements, use the dynamic block
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

  # Additional policy statements
  # which can be added using the additional_policy_statements variable
  dynamic "statement" {
    for_each = var.additional_policy_statements
    content {
      sid    = statement.value.sid
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
