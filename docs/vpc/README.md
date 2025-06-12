# VPC for CloudHSM Module - Technical Specification

## Objective

Create a specialized VPC Terraform module designed specifically for AWS CloudHSM deployment requirements. The module should provide secure, isolated network infrastructure that meets CloudHSM's specific networking needs while maintaining cost optimization and educational focus.

## Architecture Overview

CloudHSM requires specific network architecture:

- **Private Subnets Only**: HSM instances must be in private subnets across multiple AZs
- **No Direct Internet Access**: HSM instances communicate only within VPC
- **Secure Management Access**: Controlled administrative access through bastion hosts or VPN
- **Service Endpoints**: VPC endpoints for AWS services to avoid internet routing

## Module Structure

```bash
modules/vpc_cloudhsm/
├── main.tf          # Core VPC resources
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── locals.tf        # Local calculations
├── versions.tf      # Provider requirements
├── README.md        # Documentation
└── tests/
    ├── basic.tftest.hcl
    ├── multi_az.tftest.hcl
    └── endpoints.tftest.hcl
```

## Technical Requirements

### 1. Core VPC Resources

```hcl
# Required Resources
resource "aws_vpc" "cloudhsm_vpc"
resource "aws_subnet" "hsm_private_subnets"      # Multi-AZ private subnets
resource "aws_route_table" "hsm_private"         # Private routing
resource "aws_internet_gateway" "hsm_igw"        # For NAT gateway only
resource "aws_nat_gateway" "hsm_nat"             # Conditional outbound access
resource "aws_security_group" "hsm_cluster"      # HSM communication
resource "aws_security_group" "hsm_management"   # Management access
```

### 2. Network Design Requirements

| Component           | Specification                   | Justification                          |
| ------------------- | ------------------------------- | -------------------------------------- |
| **VPC CIDR**        | /16 minimum (e.g., 10.1.0.0/16) | Sufficient address space for expansion |
| **Private Subnets** | /24 per AZ, minimum 2 AZs       | CloudHSM HA requirement                |
| **Public Subnets**  | Optional, /24 per AZ            | For NAT gateways if needed             |
| **Route Tables**    | Separate for private/public     | Network isolation                      |
| **NAT Gateway**     | Optional, single shared         | Cost optimization                      |

### 3. Security Groups Design

#### HSM Cluster Security Group

```yaml
Name: ${environment}-cloudhsm-cluster-sg
Inbound Rules:
  - Port 2223-2225/TCP from VPC CIDR    # HSM client communication
  - Port 443/TCP from management SG     # HTTPS management
Outbound Rules:
  - Port 443/TCP to 0.0.0.0/0          # AWS API calls
  - All traffic to VPC CIDR             # Internal communication
```

#### HSM Management Security Group

```yaml
Name: ${environment}-cloudhsm-mgmt-sg
Inbound Rules:
  - Port 22/TCP from admin_cidr_blocks   # SSH access
  - Port 443/TCP from admin_cidr_blocks  # Web console
Outbound Rules:
  - Port 443/TCP to 0.0.0.0/0          # Internet access
  - Port 2223-2225/TCP to HSM cluster   # HSM communication
```

### 4. VPC Endpoints (Cost Optimization)

```hcl
# Gateway Endpoints (Free)
resource "aws_vpc_endpoint" "s3"
resource "aws_vpc_endpoint" "dynamodb"

# Interface Endpoints (Conditional)
resource "aws_vpc_endpoint" "kms"        # If create_kms_endpoint = true
resource "aws_vpc_endpoint" "logs"       # If enable_logging = true
resource "aws_vpc_endpoint" "ssm"        # If enable_ssm_access = true
```

### 5. Variables Design

```hcl
###############################################################################
# Network Configuration
###############################################################################
variable "environment_name" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for CloudHSM VPC"
  type        = string
  default     = "10.1.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of AZs for HSM deployment (minimum 2)"
  type        = list(string)
  default     = []  # Auto-discover if empty

  validation {
    condition     = length(var.availability_zones) == 0 || length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones required for CloudHSM HA."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for HSM private subnets"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (NAT gateways)"
  type        = list(string)
  default     = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
}

###############################################################################
# CloudHSM Specific Configuration
###############################################################################
variable "create_nat_gateway" {
  description = "Create NAT gateway for outbound internet access"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT gateway to reduce costs"
  type        = bool
  default     = true
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks for administrative access"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.admin_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All admin CIDR blocks must be valid IPv4 CIDR notation."
  }
}

###############################################################################
# VPC Endpoints Configuration
###############################################################################
variable "create_vpc_endpoints" {
  description = "Create VPC endpoints for AWS services"
  type        = bool
  default     = true
}

variable "create_kms_endpoint" {
  description = "Create VPC endpoint for KMS service"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  type        = bool
  default     = true
}

###############################################################################
# Monitoring and Logging
###############################################################################
variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs for security monitoring"
  type        = bool
  default     = false  # Cost optimization for learning
}

variable "flow_logs_retention_days" {
  description = "CloudWatch Logs retention period for VPC Flow Logs"
  type        = number
  default     = 7
}

###############################################################################
# Tagging
###############################################################################
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
```

### 6. Outputs Design

```hcl
###############################################################################
# VPC Information
###############################################################################
output "vpc_id" {
  description = "ID of the CloudHSM VPC"
  value       = aws_vpc.cloudhsm_vpc.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.cloudhsm_vpc.cidr_block
}

###############################################################################
# Subnet Information
###############################################################################
output "private_subnet_ids" {
  description = "List of private subnet IDs for CloudHSM"
  value       = aws_subnet.hsm_private_subnets[*].id
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.hsm_private_subnets[*].cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (if created)"
  value       = try(aws_subnet.hsm_public_subnets[*].id, [])
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = local.azs
}

###############################################################################
# Security Groups
###############################################################################
output "hsm_cluster_security_group_id" {
  description = "Security group ID for CloudHSM cluster"
  value       = aws_security_group.hsm_cluster.id
}

output "hsm_management_security_group_id" {
  description = "Security group ID for CloudHSM management"
  value       = aws_security_group.hsm_management.id
}

###############################################################################
# Routing Information
###############################################################################
output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.hsm_private[*].id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = try(aws_nat_gateway.hsm_nat[*].id, [])
}

###############################################################################
# VPC Endpoints
###############################################################################
output "vpc_endpoint_s3_id" {
  description = "S3 VPC endpoint ID"
  value       = try(aws_vpc_endpoint.s3[0].id, null)
}

output "vpc_endpoint_kms_id" {
  description = "KMS VPC endpoint ID"
  value       = try(aws_vpc_endpoint.kms[0].id, null)
}

###############################################################################
# Cost Information
###############################################################################
output "estimated_monthly_cost_usd" {
  description = "Estimated monthly cost for VPC infrastructure"
  value = format("%.2f",
    (var.create_nat_gateway ? (var.single_nat_gateway ? 32.85 : 32.85 * length(local.azs)) : 0) +
    (var.create_vpc_endpoints && var.create_kms_endpoint ? 7.30 : 0) # KMS interface endpoint
  )
}

output "cost_breakdown" {
  description = "Detailed cost breakdown"
  value = {
    nat_gateways = var.create_nat_gateway ? (var.single_nat_gateway ? "1 x $32.85" : "${length(local.azs)} x $32.85") : "0"
    kms_endpoint = var.create_vpc_endpoints && var.create_kms_endpoint ? "1 x $7.30" : "0"
    note = "Costs are approximate monthly USD estimates"
  }
}
```

### 7. Local Values Design

```hcl
locals {
  # Auto-discover AZs if not specified
  azs = length(var.availability_zones) > 0 ? var.availability_zones : [
    for az in data.aws_availability_zones.available.names : az
    if length(regexall("^${data.aws_region.current.name}[a-c]$", az)) > 0
  ][0:min(3, length(data.aws_availability_zones.available.names))]

  # Validate subnet configuration
  az_count = length(local.azs)

  # Common tags
  common_tags = merge(var.tags, {
    Module      = "vpc-cloudhsm"
    Purpose     = "CloudHSM Infrastructure"
    Environment = var.environment_name
  })

  # Cost optimization flags
  is_production = var.environment_name == "prod"
  enable_ha_nat = local.is_production ? !var.single_nat_gateway : false
}
```

### 8. CloudHSM-Specific Features

#### Network ACLs (Optional Enhanced Security)

```hcl
resource "aws_network_acl" "hsm_private" {
  count  = var.enable_network_acls ? 1 : 0
  vpc_id = aws_vpc.cloudhsm_vpc.id

  # HSM communication ports
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    from_port  = 2223
    to_port    = 2225
    cidr_block = var.vpc_cidr
    action     = "allow"
  }

  # Management HTTPS
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = var.vpc_cidr
    action     = "allow"
  }
}
```

#### DNS Resolution for CloudHSM

```hcl
resource "aws_vpc_dhcp_options" "cloudhsm" {
  count = var.enable_custom_dns ? 1 : 0

  domain_name         = "${data.aws_region.current.name}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = merge(local.common_tags, {
    Name = "${var.environment_name}-cloudhsm-dhcp"
  })
}
```

## Integration Points

### 1. CloudHSM Module Integration

```hcl
# In modules/cloudhsm/main.tf
module "vpc" {
  source = "../vpc_cloudhsm"

  environment_name    = var.environment_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  admin_cidr_blocks  = var.admin_cidr_blocks

  tags = var.tags
}

# Use VPC outputs
resource "aws_cloudhsm_v2_cluster" "hsm_cluster" {
  hsm_type   = var.hsm_type
  subnet_ids = module.vpc.private_subnet_ids

  tags = var.tags
}
```

### 2. Existing KMS Module

No changes required - integration happens at CloudHSM module level.

## Testing Strategy

### Test Cases

1. **basic.tftest.hcl**: VPC creation with minimal configuration
2. **multi_az.tftest.hcl**: Multi-AZ deployment validation
3. **endpoints.tftest.hcl**: VPC endpoints functionality
4. **cost_optimized.tftest.hcl**: Single NAT gateway configuration

### Validation Points

- Subnet count matches AZ count
- Private subnets have no direct internet route
- Security groups allow HSM communication ports
- VPC endpoints reduce data transfer costs
- Cost estimates are accurate

## Best Practices Implementation

1. **Cost Optimization**: Single NAT gateway option, gateway endpoints
2. **Security**: Private subnets only, restricted security groups
3. **High Availability**: Multi-AZ subnet distribution
4. **Monitoring**: Optional VPC Flow Logs
5. **Maintainability**: Clear variable naming, comprehensive outputs
6. **Educational**: Cost breakdowns, clear documentation

## Success Criteria

1. ✅ VPC meets CloudHSM networking requirements
2. ✅ Security groups properly configured for HSM communication
3. ✅ Cost-optimized defaults for learning environment
4. ✅ Seamless integration with CloudHSM module
5. ✅ Comprehensive test coverage
6. ✅ Clear cost transparency and estimation

## Development Phases

1. **Phase 1**: Basic VPC structure and variables
2. **Phase 2**: Subnet and routing configuration
3. **Phase 3**: Security groups for CloudHSM
4. **Phase 4**: VPC endpoints and cost optimization
5. **Phase 5**: Integration testing with CloudHSM module
6. **Phase 6**: Documentation and examples
