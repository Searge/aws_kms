variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "org_policies" {
  description = "Map of organization policies to create and attach"
  type = map(object({
    name        = string
    description = string
    policy      = string
    policy_file = optional(string)
    targets     = optional(list(object({
      target_id = string
      type      = string # Can be "ROOT", "ORGANIZATIONAL_UNIT", or "ACCOUNT"
    })), [])
    tags        = optional(map(string), {})
  }))
  default     = {}

  validation {
    condition     = alltrue([
      for k, v in var.org_policies :
        (v.policy != null && v.policy_file == null) ||
        (v.policy == null && v.policy_file != null)
    ])
    error_message = "Each policy must specify either 'policy' or 'policy_file', but not both."
  }
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "naming_prefix" {
  description = "Prefix to use for resource naming"
  type        = string
  default     = ""
}

variable "kms_tag_enforcement_enabled" {
  description = "Enable KMS tag enforcement policy"
  type        = bool
  default     = false
}

variable "kms_waiting_period_enabled" {
  description = "Enable KMS waiting period policy"
  type        = bool
  default     = false
}

variable "kms_environment_enforcement_enabled" {
  description = "Enable KMS environment enforcement policy"
  type        = bool
  default     = false
}

variable "environment_tags" {
  description = "Valid environment tag values"
  type        = list(string)
  default     = ["dev", "test", "stage", "prod"]
}

variable "kms_deletion_waiting_period_days" {
  description = "Minimum waiting period in days for KMS key deletion"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_waiting_period_days >= 7 && var.kms_deletion_waiting_period_days <= 30
    error_message = "KMS deletion waiting period must be between 7 and 30 days."
  }
}

variable "environment_ou_mapping" {
  description = "Mapping of environment to OU paths"
  type        = map(string)
  default     = {
    "dev"   = "/root/dev/*"
    "test"  = "/root/test/*"
    "stage" = "/root/stage/*"
    "prod"  = "/root/prod/*"
  }
}

variable "policy_targets" {
  description = "Map of policy names to target IDs"
  type = map(list(object({
    target_id = string
    type      = string
  })))
  default     = {}
}
