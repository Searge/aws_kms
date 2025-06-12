###############################################################################
# CloudHSM Cluster Security Group
###############################################################################
resource "aws_security_group" "hsm_cluster" {
  name_prefix = "${var.environment_name}-cloudhsm-cluster-"
  description = "Security group for CloudHSM cluster communication"
  vpc_id      = aws_vpc.cloudhsm_vpc.id

  # HSM client communication (ports 2223-2225)
  ingress {
    description = "CloudHSM client communication"
    from_port   = 2223
    to_port     = 2225
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # HTTPS management from admin networks (instead of management SG)
  dynamic "ingress" {
    for_each = var.enable_hsm_management_access && length(var.admin_cidr_blocks) > 0 ? [1] : []
    content {
      description = "HTTPS management access from admin networks"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.admin_cidr_blocks
    }
  }

  # Outbound AWS API calls
  egress {
    description = "AWS API access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound DNS
  egress {
    description = "DNS resolution"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-cloudhsm-cluster-sg"
    Type = "CloudHSM-Cluster"
  })

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# CloudHSM Management Security Group
###############################################################################
resource "aws_security_group" "hsm_management" {
  count = var.enable_hsm_management_access ? 1 : 0

  name_prefix = "${var.environment_name}-cloudhsm-mgmt-"
  description = "Security group for CloudHSM management access"
  vpc_id      = aws_vpc.cloudhsm_vpc.id

  # SSH access from admin networks
  dynamic "ingress" {
    for_each = length(var.admin_cidr_blocks) > 0 ? [1] : []
    content {
      description = "SSH admin access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.admin_cidr_blocks
    }
  }

  # HTTPS management console access
  dynamic "ingress" {
    for_each = length(var.admin_cidr_blocks) > 0 ? [1] : []
    content {
      description = "HTTPS management console"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.admin_cidr_blocks
    }
  }

  # Outbound to HSM cluster (using CIDR instead of SG reference to avoid cycle)
  egress {
    description = "HSM cluster communication"
    from_port   = 2223
    to_port     = 2225
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Outbound HTTPS
  egress {
    description = "Internet HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound DNS
  egress {
    description = "DNS resolution"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-cloudhsm-management-sg"
    Type = "CloudHSM-Management"
  })

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# Default VPC Security Group (restrict default)
###############################################################################
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.cloudhsm_vpc.id

  # Remove all default rules for security
  ingress = []
  egress  = []

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-cloudhsm-default-sg-restricted"
  })
}
