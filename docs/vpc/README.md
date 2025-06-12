# VPC for CloudHSM Module Development - Technical Specification

## Objective

Create a specialized VPC Terraform module designed for AWS CloudHSM deployment requirements within the existing AWS KMS Security Framework. The module should provide secure, isolated network infrastructure that meets CloudHSM's specific networking needs while maintaining educational focus and cost optimization.

## Architecture Overview

Implement **dedicated VPC module** specifically for CloudHSM with integration into existing `modules/cloudhsm` module structure.

CloudHSM networking requirements:

- **Private Subnets Only**: HSM instances must be deployed in private subnets across multiple AZs
- **Controlled Outbound Access**: Limited internet access through NAT gateways for AWS API communication
- **Specific Port Requirements**: HSM communication uses ports 2223-2225/TCP
- **High Availability**: Minimum 2 AZs required for production CloudHSM clusters

## Module Structure

```bash
modules/vpc_cloudhsm/
├── main.tf          # Core VPC, subnets, routing resources
├── security.tf      # Security groups for CloudHSM communication
├── endpoints.tf     # VPC endpoints for cost optimization
├── variables.tf     # Input variables with validation
├── outputs.tf       # Output values for CloudHSM integration
├── locals.tf        # Local calculations and data sources
├── versions.tf      # Provider requirements (align with existing)
├── README.md        # Module documentation
└── tests/
    ├── basic.tftest.hcl        # Basic VPC creation
    ├── multi_az.tftest.hcl     # Multi-AZ validation
    └── integration.tftest.hcl  # CloudHSM integration test
```

## Technical Requirements

### 1. Core Network Resources

- **VPC**: Dedicated VPC with customizable CIDR block
- **Private Subnets**: Multi-AZ private subnets for HSM instances
- **Public Subnets**: Optional public subnets for NAT gateways
- **Internet Gateway**: For NAT gateway connectivity
- **NAT Gateway(s)**: Configurable (single vs per-AZ for cost optimization)
- **Route Tables**: Separate routing for private/public subnets

### 2. CloudHSM Security Groups (in security.tf)

```yaml
HSM Cluster Security Group:
- Inbound: 2223-2225/TCP from VPC CIDR (HSM client communication)
- Inbound: 443/TCP from management SG (HTTPS management)
- Outbound: 443/TCP to 0.0.0.0/0 (AWS API calls)

HSM Management Security Group:
- Inbound: 22/TCP from admin CIDR blocks (SSH access)
- Inbound: 443/TCP from admin CIDR blocks (Management console)
- Outbound: 2223-2225/TCP to HSM cluster SG
- Outbound: 443/TCP to 0.0.0.0/0 (Internet access)
```

### 3. VPC Endpoints (in endpoints.tf)

- **Gateway Endpoints**: S3, DynamoDB (free tier)
- **Interface Endpoints**: KMS, CloudWatch Logs (conditional)
- Cost optimization through reduced NAT gateway usage

### 4. Integration with Existing CloudHSM Module

Modify `modules/cloudhsm/main.tf` to consume VPC module:

```hcl
module "vpc" {
  source = "../vpc_cloudhsm"

  environment_name     = var.environment_name
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  admin_cidr_blocks   = var.admin_ssh_cidr_blocks

  # Cost optimization
  single_nat_gateway  = var.environment_name != "prod"
  create_vpc_endpoints = true

  tags = var.tags
}

# Use VPC outputs in CloudHSM resources
resource "aws_cloudhsm_v2_cluster" "hsm_cluster" {
  hsm_type   = var.hsm_type
  subnet_ids = module.vpc.private_subnet_ids

  tags = var.tags
}
```

### 5. Variables Design

```hcl
# Required Variables
variable "environment_name" { type = string }
variable "vpc_cidr" { type = string, default = "10.1.0.0/16" }

# CloudHSM Specific
variable "availability_zones" { type = list(string), default = [] }
variable "admin_cidr_blocks" { type = list(string), default = [] }

# Cost Optimization
variable "single_nat_gateway" { type = bool, default = true }
variable "create_vpc_endpoints" { type = bool, default = true }

# Validation rules for CloudHSM requirements
validation {
  condition = length(var.availability_zones) >= 2
  error_message = "CloudHSM requires minimum 2 AZs for HA."
}
```

### 6. Outputs for CloudHSM Integration

```hcl
# Network Infrastructure
output "vpc_id" { value = aws_vpc.cloudhsm_vpc.id }
output "private_subnet_ids" { value = aws_subnet.hsm_private[*].id }

# Security Groups
output "hsm_cluster_security_group_id" { value = aws_security_group.hsm_cluster.id }
output "hsm_management_security_group_id" { value = aws_security_group.hsm_management.id }

# Cost Information
output "estimated_monthly_cost_usd" {
  description = "Estimated monthly VPC infrastructure costs"
  value = "calculated_cost"
}
```

## Key Constraints

- **Educational Focus**: Prioritize learning over production complexity
- **Budget Conscious**: Implement cost controls and cost transparency
- **Clean Integration**: Seamless integration with existing CloudHSM module
- **English Only**: All code and comments in English
- **Consistent Versioning**: Align with existing module requirements (Terraform >= 1.10, AWS ~> 5.94)

## Prerequisites Documentation

Document in README.md:

- CloudHSM networking requirements explanation
- VPC design decisions and trade-offs
- Cost implications of different configurations
- Integration examples with CloudHSM module

## Success Criteria

1. Module creates VPC infrastructure suitable for CloudHSM deployment
2. Security groups properly configured for HSM communication ports
3. Seamless integration with existing `modules/cloudhsm` structure
4. Cost-optimized defaults for educational environments
5. Comprehensive input validation prevents misconfigurations
6. Clear documentation for educational use
7. All security best practices implemented

## Development Phases

1. **Phase 1**: Basic module structure (versions.tf, variables.tf, outputs.tf)
2. **Phase 2**: Core VPC infrastructure (main.tf)
3. **Phase 3**: CloudHSM security groups (security.tf)
4. **Phase 4**: VPC endpoints for cost optimization (endpoints.tf)
5. **Phase 5**: Local calculations and validation (locals.tf)
6. **Phase 6**: Integration with CloudHSM module
7. **Phase 7**: Terraform tests
8. **Phase 8**: Documentation and examples

## Integration Points

### CloudHSM Module Consumption

The VPC module will be consumed by CloudHSM module through:

- **Network**: Private subnet IDs for HSM cluster placement
- **Security**: Security group IDs for HSM communication
- **Cost**: Shared infrastructure costs in estimations

### Existing KMS Module

No direct integration required - connection happens through CloudHSM module layer.

## Cost Optimization Features

- Single NAT gateway option for non-production environments
- Gateway VPC endpoints to reduce data transfer costs
- Cost estimation outputs for budget planning
- Environment-based configuration recommendations
