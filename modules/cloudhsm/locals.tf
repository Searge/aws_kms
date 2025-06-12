locals {
  # Common tags
  common_tags = merge(var.tags, {
    Environment = var.environment_name
    Module      = "cloudhsm"
    Purpose     = "AWS CloudHSM with KMS integration"
    CostCenter  = "Infrastructure"
    Terraform   = "true"
  })

  # Custom key store configuration
  custom_key_store_name = var.custom_key_store_name != "" ? var.custom_key_store_name : "${var.environment_name}-hsm-keystore-${random_id.suffix.hex}"

  # Key store password from Secrets Manager or default for dev
  key_store_password = var.hsm_password_secret_arn != "" ? data.aws_secretsmanager_secret_version.hsm_password[0].secret_string : (
    var.environment_name != "prod" ? "TempPassword123!" : null
  )

  # Trust anchor certificate
  trust_anchor_certificate = var.trust_anchor_certificate_path != "" ? file(var.trust_anchor_certificate_path) : null

  # Cost calculation helpers
  hours_per_month = 24 * 30
  hsm_hourly_cost = var.hsm_type == "hsm1.medium" ? 1.60 : 1.60 # Cost per hour per HSM

  # Monthly cost estimation
  estimated_hsm_cost   = var.hsm_instance_count * local.hours_per_month * local.hsm_hourly_cost
  estimated_vpc_cost   = 55.0 # Approximate VPC infrastructure cost from vpc_cloudhsm module
  total_estimated_cost = local.estimated_hsm_cost + local.estimated_vpc_cost
}

# Data source for HSM password from Secrets Manager
data "aws_secretsmanager_secret_version" "hsm_password" {
  count = var.hsm_password_secret_arn != "" ? 1 : 0

  secret_id = var.hsm_password_secret_arn
}
