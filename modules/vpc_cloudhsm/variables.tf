###############################################################################
# Environment Configuration
###############################################################################
variable "environment_name" {
  description = "Environment name for deployment (dev, prod, etc.)"
  type        = string

  validation {
    condition     = length(var.environment_name) >= 2 && var.environment_name != null && var.environment_name != ""
    error_message = "Error: Environment name must be at least 2 characters long."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}

  validation {
    condition = length(var.tags) == 0 || (
      contains(keys(var.tags), "owner") &&
      contains(keys(var.tags), "environment") &&
      contains(keys(var.tags), "data-classification")
    )
    error_message = "Tags map must include 'owner', 'environment', and 'data-classification' keys when provided."
  }
}

###############################################################################
# Network Configuration
###############################################################################
variable "vpc_cidr" {
  description = "CIDR block for the CloudHSM VPC"
  type        = string
  default     = "10.1.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones to deploy subnets (minimum 2 required for CloudHSM HA)"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.availability_zones) == 0 || length(var.availability_zones) >= 2
    error_message = "CloudHSM requires minimum 2 availability zones for high availability."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (must match number of AZs)"
  type        = list(string)
  default     = []

  validation {
    condition = length(var.private_subnet_cidrs) == 0 || (
      length(var.private_subnet_cidrs) >= 2 &&
      alltrue([for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))])
    )
    error_message = "At least 2 valid private subnet CIDRs must be provided for CloudHSM HA deployment."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (for NAT gateways)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All public subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

###############################################################################
# CloudHSM Security Configuration
###############################################################################
variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed SSH and management access to CloudHSM"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.admin_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All admin CIDR blocks must be valid IPv4 CIDR notation."
  }
}

variable "enable_hsm_management_access" {
  description = "Enable management access security group for CloudHSM administration"
  type        = bool
  default     = true
}

###############################################################################
# Cost Optimization Configuration
###############################################################################
variable "single_nat_gateway" {
  description = "Use single NAT gateway instead of per-AZ for cost optimization"
  type        = bool
  default     = true
}

variable "create_vpc_endpoints" {
  description = "Create VPC endpoints for S3, DynamoDB, and KMS to reduce NAT costs"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Create NAT gateway for private subnet internet access (required for CloudHSM)"
  type        = bool
  default     = true
}

variable "nat_gateway_eip_allocation_ids" {
  description = "Pre-allocated EIP allocation IDs for NAT gateways (optional)"
  type        = list(string)
  default     = []
}

###############################################################################
# DNS Configuration
###############################################################################
variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}
