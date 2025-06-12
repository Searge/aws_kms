###############################################################################
# CloudHSM Service Role
###############################################################################
resource "aws_iam_role" "cloudhsm_service_role" {
  count = var.hsm_instance_count > 0 ? 1 : 0

  name = "${var.environment_name}-cloudhsm-service-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudhsm.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cloudhsm_service_role_policy" {
  count = var.hsm_instance_count > 0 ? 1 : 0

  role       = aws_iam_role.cloudhsm_service_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/CloudHSMServiceRolePolicy"
}

###############################################################################
# HSM Administration Role
###############################################################################
resource "aws_iam_role" "hsm_admin_role" {
  count = var.hsm_instance_count > 0 ? 1 : 0

  name = "${var.environment_name}-hsm-admin-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "hsm_admin_policy" {
  count = var.hsm_instance_count > 0 ? 1 : 0

  name = "${var.environment_name}-hsm-admin-policy"
  role = aws_iam_role.hsm_admin_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudhsm:DescribeClusters",
          "cloudhsm:DescribeBackups",
          "cloudhsm:ListTags",
          "cloudhsm:CreateHsm",
          "cloudhsm:DescribeHsm",
          "cloudhsm:DeleteHsm"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = var.enable_hsm_logging ? aws_cloudwatch_log_group.hsm_logs[0].arn : "*"
      }
    ]
  })
}

###############################################################################
# KMS-CloudHSM Integration Role
###############################################################################
resource "aws_iam_role" "kms_hsm_role" {
  count = var.create_custom_key_store && var.hsm_instance_count > 0 ? 1 : 0

  name = "${var.environment_name}-kms-hsm-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "kms.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "kms_hsm_policy" {
  count = var.create_custom_key_store && var.hsm_instance_count > 0 ? 1 : 0

  name = "${var.environment_name}-kms-hsm-policy"
  role = aws_iam_role.kms_hsm_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudhsm:DescribeClusters",
          "cloudhsm:ConnectCustomKeyStore",
          "cloudhsm:DisconnectCustomKeyStore"
        ]
        Resource = var.hsm_instance_count > 0 ? aws_cloudhsm_v2_cluster.hsm_cluster[0].arn : "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.hsm_password_secret_arn != "" ? var.hsm_password_secret_arn : "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}
