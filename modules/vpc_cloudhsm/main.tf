###############################################################################
# VPC Core Infrastructure
###############################################################################
resource "aws_vpc" "cloudhsm_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-cloudhsm-vpc"
  })
}

###############################################################################
# Internet Gateway
###############################################################################
resource "aws_internet_gateway" "cloudhsm_igw" {
  count  = var.enable_nat_gateway ? 1 : 0
  vpc_id = aws_vpc.cloudhsm_vpc.id

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-cloudhsm-igw"
  })
}

###############################################################################
# Public Subnets (for NAT Gateways)
###############################################################################
resource "aws_subnet" "public" {
  count = var.enable_nat_gateway ? length(local.availability_zones) : 0

  vpc_id                  = aws_vpc.cloudhsm_vpc.id
  cidr_block              = local.calculated_public_cidrs[count.index]
  availability_zone       = local.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-cloudhsm-public-${local.availability_zones[count.index]}"
    Type = "Public"
  })
}

###############################################################################
# Private Subnets (for CloudHSM instances)
###############################################################################
resource "aws_subnet" "private" {
  count = length(local.availability_zones)

  vpc_id            = aws_vpc.cloudhsm_vpc.id
  cidr_block        = local.calculated_private_cidrs[count.index]
  availability_zone = local.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-cloudhsm-private-${local.availability_zones[count.index]}"
    Type = "Private"
  })
}

###############################################################################
# Elastic IPs for NAT Gateways
###############################################################################
resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-cloudhsm-nat-eip-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.cloudhsm_igw]
}

###############################################################################
# NAT Gateways
###############################################################################
resource "aws_nat_gateway" "cloudhsm_nat" {
  count = local.nat_gateway_count

  allocation_id = length(var.nat_gateway_eip_allocation_ids) > 0 ? var.nat_gateway_eip_allocation_ids[count.index] : aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[var.single_nat_gateway ? 0 : count.index].id

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-cloudhsm-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.cloudhsm_igw]
}

###############################################################################
# Route Tables
###############################################################################

# Public Route Table
resource "aws_route_table" "public" {
  count  = var.enable_nat_gateway ? 1 : 0
  vpc_id = aws_vpc.cloudhsm_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudhsm_igw[0].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-cloudhsm-public-rt"
    Type = "Public"
  })
}

# Private Route Tables
resource "aws_route_table" "private" {
  count  = length(local.availability_zones)
  vpc_id = aws_vpc.cloudhsm_vpc.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.cloudhsm_nat[0].id : aws_nat_gateway.cloudhsm_nat[count.index].id
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-cloudhsm-private-rt-${local.availability_zones[count.index]}"
    Type = "Private"
  })
}

###############################################################################
# Route Table Associations
###############################################################################

# Public subnet associations
resource "aws_route_table_association" "public" {
  count = var.enable_nat_gateway ? length(aws_subnet.public) : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Private subnet associations
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
