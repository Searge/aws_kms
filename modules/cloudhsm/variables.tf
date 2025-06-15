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
  description = "List of availability zones to deploy HSM instances (minimum 2 required for HA)"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.availability_zones) == 0 || length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones must be specified for high availability."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (must match number of AZs)"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least 2 private subnet CIDRs must be provided for HA deployment."
  }
}

###############################################################################
# CloudHSM Configuration
###############################################################################
variable "hsm_type" {
  description = "CloudHSM instance type"
  type        = string
  default     = "hsm1.medium"

  validation {
    condition     = contains(["hsm1.medium"], var.hsm_type)
    error_message = "HSM type must be hsm1.medium (cost-optimized for learning)."
  }
}

variable "hsm_instance_count" {
  description = "Number of HSM instances to create (minimum 2 for production HA)"
  type        = number
  default     = 2

  validation {
    condition     = var.hsm_instance_count >= 1 && var.hsm_instance_count <= 28
    error_message = "HSM instance count must be between 1 and 28."
  }
}

###############################################################################
# KMS Custom Key Store Configuration
###############################################################################
variable "create_custom_key_store" {
  description = "Whether to create a KMS custom key store backed by CloudHSM"
  type        = bool
  default     = true
}

variable "custom_key_store_name" {
  description = "Name for the KMS custom key store"
  type        = string
  default     = ""
}

variable "trust_anchor_certificate_path" {
  description = "Path to trust anchor certificate file (optional for dev environments)"
  type        = string
  default     = ""
}

###############################################################################
# Security Configuration
###############################################################################
variable "hsm_password_secret_arn" {
  description = "ARN of AWS Secrets Manager secret containing HSM user password"
  type        = string
  default     = ""
}

variable "admin_ssh_cidr_blocks" {
  description = "CIDR blocks allowed SSH access to HSM management"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.admin_ssh_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All admin SSH CIDR blocks must be valid IPv4 CIDR notation."
  }
}

variable "enable_hsm_logging" {
  description = "Enable CloudWatch logging for HSM cluster"
  type        = bool
  default     = true
}

###############################################################################
# Cost Optimization
###############################################################################
variable "auto_cleanup_enabled" {
  description = "Enable automatic cleanup for cost optimization in non-prod environments"
  type        = bool
  default     = false
}
