# VPC CloudHSM Terraform Module

A specialized VPC module designed for AWS CloudHSM deployment requirements, providing secure and cost-optimized network infrastructure within the AWS KMS Security Framework.

## 🎯 Overview

This module creates VPC infrastructure specifically optimized for CloudHSM deployment with:

- **Multi-AZ private subnets** for CloudHSM high availability
- **CloudHSM-specific security groups** with proper port configurations (2223-2225/TCP)
- **Cost-optimized NAT gateway options** (single vs per-AZ)
- **VPC endpoints** for reducing data transfer costs
- **Educational focus** with clear cost transparency

## 🏗️ Architecture

```txt
┌─────────────────────────────────────────────────────────────┐
│                    CloudHSM VPC                            │
│  ┌─────────────────┐              ┌─────────────────┐      │
│  │   Public-AZ-1   │              │   Public-AZ-2   │      │
│  │  (NAT Gateway)  │              │  (Optional NAT) │      │
│  └─────────────────┘              └─────────────────┘      │
│           │                                 │               │
│  ┌─────────────────┐              ┌─────────────────┐      │
│  │  Private-AZ-1   │              │  Private-AZ-2   │      │
│  │ (CloudHSM-1)    │              │ (CloudHSM-2)    │      │
│  └─────────────────┘              └─────────────────┘      │
│                                                             │
│  VPC Endpoints: S3, DynamoDB (free) + KMS (paid)          │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Basic Configuration

```hcl
module "vpc_cloudhsm" {
  source = "./modules/vpc_cloudhsm"

  environment_name = "dev"
  vpc_cidr        = "10.1.0.0/16"

  # CloudHSM requires minimum 2 AZs
  availability_zones = ["us-east-1a", "us-east-1b"]

  # Cost optimization for dev environment
  single_nat_gateway    = true
  create_vpc_endpoints  = true

  tags = {
    owner               = "DevOps Team"
    environment         = "dev"
    data-classification = "internal"
  }
}
```

### Production Configuration

```hcl
module "vpc_cloudhsm" {
  source = "./modules/vpc_cloudhsm"

  environment_name = "prod"
  vpc_cidr        = "10.0.0.0/16"

  # Explicit subnet planning for production
  availability_zones    = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # High availability with per-AZ NAT gateways
  single_nat_gateway = false

  # Management access for admin team
  admin_cidr_blocks = ["203.0.113.0/24"]  # Replace with your admin network

  tags = {
    owner               = "Security Team"
    environment         = "prod"
    data-classification = "confidential"
  }
}
```

## 📋 CloudHSM Integration

This module is designed to integrate seamlessly with the CloudHSM module:

```hcl
module "vpc" {
  source = "../modules/vpc_cloudhsm"

  environment_name     = var.environment_name
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  admin_cidr_blocks   = var.admin_ssh_cidr_blocks

  # Cost optimization
  single_nat_gateway  = var.environment_name != "prod"
  create_vpc_endpoints = true

  tags = var.tags
}

# CloudHSM cluster using VPC outputs
resource "aws_cloudhsm_v2_cluster" "hsm_cluster" {
  hsm_type   = var.hsm_type
  subnet_ids = module.vpc.private_subnet_ids

  tags = var.tags
}
```

## 🔒 Security Features

### CloudHSM Security Groups

1. **HSM Cluster Security Group** (`hsm_cluster_security_group_id`)
   - Inbound: Ports 2223-2225/TCP from VPC CIDR
   - Inbound: Port 443/TCP from management SG
   - Outbound: Port 443/TCP for AWS API calls

2. **HSM Management Security Group** (`hsm_management_security_group_id`)
   - Inbound: Port 22/TCP from admin CIDR blocks
   - Inbound: Port 443/TCP from admin CIDR blocks
   - Outbound: Ports 2223-2225/TCP to HSM cluster

### Network Security

- **Default security group** is restricted (no rules)
- **VPC endpoints** with account-restricted policies
- **Private subnets only** for CloudHSM instances
- **Controlled internet access** through NAT gateways

## 💰 Cost Optimization

### Default Cost-Saving Features

- **Single NAT Gateway**: `single_nat_gateway = true` (saves ~$45/month per AZ)
- **Gateway VPC Endpoints**: S3 and DynamoDB (free tier)
- **Environment-based optimization**: Automatic cost optimization for non-prod

### Cost Monitoring

```bash
# Check estimated costs
terraform plan
# Look for module.vpc_cloudhsm.estimated_monthly_cost_usd output

# Example output:
# estimated_monthly_cost_usd = "55.80"
# cost_breakdown = {
#   elastic_ips = "$3.60"
#   nat_gateways = "$45.00"
#   vpc_endpoints = "$7.20"
#   total = "$55.80"
# }
```

## 📊 Key Outputs

### Network Infrastructure

- `vpc_id`: VPC identifier
- `private_subnet_ids`: List of private subnet IDs for CloudHSM
- `public_subnet_ids`: List of public subnet IDs for NAT gateways

### Security Groups

- `hsm_cluster_security_group_id`: For CloudHSM cluster instances
- `hsm_management_security_group_id`: For CloudHSM management access

### Cost Information

- `estimated_monthly_cost_usd`: Total estimated monthly cost
- `cost_breakdown`: Detailed cost analysis
- `cost_optimization_recommendations`: Actionable cost advice

## ⚙️ Configuration Options

### Network Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vpc_cidr` | string | "10.1.0.0/16" | VPC CIDR block |
| `availability_zones` | list(string) | auto-detected | AZs for subnets (min 2) |
| `private_subnet_cidrs` | list(string) | auto-calculated | Private subnet CIDRs |
| `public_subnet_cidrs` | list(string) | auto-calculated | Public subnet CIDRs |

### Cost Optimization

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `single_nat_gateway` | bool | true | Use single NAT gateway |
| `create_vpc_endpoints` | bool | true | Create VPC endpoints |
| `enable_nat_gateway` | bool | true | Enable NAT gateway (required for CloudHSM) |

### Security Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `admin_cidr_blocks` | list(string) | [] | Admin network CIDR blocks |
| `enable_hsm_management_access` | bool | true | Enable management security group |

## 🧪 Terraform Tests

The module includes comprehensive tests:

```bash
# Run all tests
terraform test

# Run specific test
terraform test tests/basic.tftest.hcl
terraform test tests/multi_az.tftest.hcl
terraform test tests/integration.tftest.hcl
```

## 📋 Prerequisites

- Terraform >= 1.10
- AWS Provider ~> 5.94
- AWS credentials configured
- Understanding of CloudHSM networking requirements

## 🔍 Validation Rules

The module includes input validation for:

- **AZ Requirements**: Minimum 2 AZs for CloudHSM HA
- **CIDR Validation**: Valid IPv4 CIDR blocks
- **Subnet Matching**: CIDR count matches AZ count
- **Required Tags**: owner, environment, data-classification

## 🎯 Best Practices

1. **Environment Separation**: Use different VPCs for dev/prod
2. **Cost Monitoring**: Regular review of `cost_breakdown` output
3. **Security**: Restrict `admin_cidr_blocks` to known networks
4. **High Availability**: Use minimum 2 AZs for CloudHSM
5. **Testing**: Use Terraform tests before deployment

## 🔧 Troubleshooting

### Common Issues

1. **"Minimum 2 AZs required"**
   - Ensure `availability_zones` has at least 2 zones
   - Check if AZs are available in your region

2. **"Invalid CIDR block"**
   - Verify CIDR notation (e.g., "10.1.0.0/16")
   - Ensure no CIDR overlap with existing VPCs

3. **High costs in plan**
   - Enable `single_nat_gateway = true` for dev
   - Review `cost_optimization_recommendations` output

## 📚 Related Documentation

- [AWS CloudHSM Networking](https://docs.aws.amazon.com/cloudhsm/latest/userguide/create-subnets.html)
- [VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [CloudHSM Security Groups](https://docs.aws.amazon.com/cloudhsm/latest/userguide/configure-sg.html)

---

*This module is designed for educational purposes with cost optimization in mind. Always review AWS pricing before deployment.*
