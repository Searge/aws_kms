# Random suffix for unique resource naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

###############################################################################
# VPC Infrastructure (integrate with existing vpc_cloudhsm module)
###############################################################################
module "vpc" {
  source = "../vpc_cloudhsm"

  environment_name     = var.environment_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  admin_cidr_blocks    = var.admin_ssh_cidr_blocks

  # Cost optimization settings
  single_nat_gateway           = var.environment_name != "prod"
  create_vpc_endpoints         = true
  enable_hsm_management_access = length(var.admin_ssh_cidr_blocks) > 0

  tags = local.common_tags
}

###############################################################################
# CloudHSM Cluster
###############################################################################
resource "aws_cloudhsm_v2_cluster" "hsm_cluster" {
  count = var.hsm_instance_count > 0 ? 1 : 0

  hsm_type   = var.hsm_type
  subnet_ids = module.vpc.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-cloudhsm-cluster-${random_id.suffix.hex}"
  })

  lifecycle {
    prevent_destroy = false
  }
}

###############################################################################
# CloudHSM Instances (HSMs)
###############################################################################
resource "aws_cloudhsm_v2_hsm" "hsm_instances" {
  count = var.hsm_instance_count

  cluster_id = aws_cloudhsm_v2_cluster.hsm_cluster[0].cluster_id
  subnet_id  = module.vpc.private_subnet_ids[count.index % length(module.vpc.private_subnet_ids)]

  # Distribute HSMs across AZs for HA
  availability_zone = module.vpc.availability_zones[count.index % length(module.vpc.availability_zones)]

  lifecycle {
    prevent_destroy = false
  }

  # Ensure cluster is fully created before adding HSMs
  depends_on = [aws_cloudhsm_v2_cluster.hsm_cluster]

  timeouts {
    create = "120m"
    delete = "120m"
  }
}

###############################################################################
# KMS Custom Key Store (Optional)
###############################################################################
resource "aws_kms_custom_key_store" "hsm_key_store" {
  count = var.create_custom_key_store && var.hsm_instance_count > 0 ? 1 : 0

  cloud_hsm_cluster_id     = aws_cloudhsm_v2_cluster.hsm_cluster[0].cluster_id
  custom_key_store_name    = local.custom_key_store_name
  key_store_password       = local.key_store_password
  trust_anchor_certificate = local.trust_anchor_certificate

  # Custom key store can only be created after cluster is initialized
  # In a real scenario, this would require manual HSM initialization
  depends_on = [aws_cloudhsm_v2_hsm.hsm_instances]

  lifecycle {
    # Custom key stores require manual initialization steps
    # This prevents automatic destruction that could cause data loss
    prevent_destroy = true
  }
}

###############################################################################
# CloudWatch Log Group for HSM Logging
###############################################################################
resource "aws_cloudwatch_log_group" "hsm_logs" {
  count = var.enable_hsm_logging ? 1 : 0

  name              = "/aws/cloudhsm/${var.environment_name}-${random_id.suffix.hex}"
  retention_in_days = var.environment_name == "prod" ? 90 : 7

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-cloudhsm-logs"
  })
}

###############################################################################
# Auto-cleanup for dev environments (cost optimization)
###############################################################################
resource "null_resource" "auto_cleanup" {
  count = var.auto_cleanup_enabled && var.environment_name != "prod" ? 1 : 0

  # This creates a scheduled cleanup for development environments
  # In practice, this would be implemented through AWS Lambda or similar
  triggers = {
    cluster_id = try(aws_cloudhsm_v2_cluster.hsm_cluster[0].cluster_id, "")
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Auto-cleanup triggered for CloudHSM resources'"
  }
}
