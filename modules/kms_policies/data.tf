data "aws_caller_identity" "current" {}

###############################################################################
# AWS AIM Policy Document
#
# This data creates an IAM policy document that allows the root account
# to administrate a KMS key and allows the SSM and CloudWatch services
# to access the key for encryption and decryption operations.
###############################################################################
data "aws_iam_policy_document" "this" {
  policy_id = "key-policy-ssm-cloudwatch"
  statement {
    sid = "AllowRootAccountKMSAccess"
    actions = [
      "kms:*",
    ]
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }
    resources = ["*"]
  }
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
}
