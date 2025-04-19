###############################################################################
# AWS KMS Module
###############################################################################
resource "aws_kms_key" "main_cmk" {
  description             = "Main CMK for ${local.name_prefix} enviroment."
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.this.json
  tags                    = var.tags

}

resource "aws_kms_alias" "main_cmk_alias" {
  name          = "alias/${local.name_prefix}-aws-cmk"
  target_key_id = aws_kms_key.main_cmk.key_id
}
