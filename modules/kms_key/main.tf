###############################################################################
# AWS KMS Module
###############################################################################
resource "aws_kms_key" "kms_key" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  policy                  = var.custom_policy
  tags                    = var.tags
  custom_key_store_id     = local.custom_key_store_id
}

resource "aws_kms_alias" "key_alias" {
  depends_on    = [aws_kms_key.kms_key]
  name          = local.key_alias
  target_key_id = aws_kms_key.kms_key.key_id
}
