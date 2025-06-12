###############################################################################
# Gateway VPC Endpoints (Free Tier)
###############################################################################

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id            = aws_vpc.cloudhsm_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id
  policy            = data.aws_iam_policy_document.s3_endpoint_policy[0].json

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-cloudhsm-s3-endpoint"
    Type = "Gateway"
  })
}

# DynamoDB Gateway Endpoint
resource "aws_vpc_endpoint" "dynamodb" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id            = aws_vpc.cloudhsm_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id
  policy            = data.aws_iam_policy_document.dynamodb_endpoint_policy[0].json

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-cloudhsm-dynamodb-endpoint"
    Type = "Gateway"
  })
}

###############################################################################
# Interface VPC Endpoints (Cost Consideration)
###############################################################################

# KMS Interface Endpoint (for CloudHSM-KMS integration)
resource "aws_vpc_endpoint" "kms" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.cloudhsm_vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  policy              = data.aws_iam_policy_document.kms_endpoint_policy[0].json

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-cloudhsm-kms-endpoint"
    Type = "Interface"
  })
}

# CloudWatch Logs Interface Endpoint (optional for logging)
resource "aws_vpc_endpoint" "logs" {
  count = var.create_vpc_endpoints && var.environment_name == "prod" ? 1 : 0

  vpc_id              = aws_vpc.cloudhsm_vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-cloudhsm-logs-endpoint"
    Type = "Interface"
  })
}

###############################################################################
# VPC Endpoints Security Group
###############################################################################
resource "aws_security_group" "vpc_endpoints" {
  count = var.create_vpc_endpoints ? 1 : 0

  name_prefix = "${var.environment_name}-cloudhsm-endpoints-"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.cloudhsm_vpc.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-cloudhsm-endpoints-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# VPC Endpoint Policies
###############################################################################

data "aws_iam_policy_document" "s3_endpoint_policy" {
  count = var.create_vpc_endpoints ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

data "aws_iam_policy_document" "dynamodb_endpoint_policy" {
  count = var.create_vpc_endpoints ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

data "aws_iam_policy_document" "kms_endpoint_policy" {
  count = var.create_vpc_endpoints ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}
