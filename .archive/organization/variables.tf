variable "aws_region" {
  description = "AWS region for the organization management account"
  type        = string
  default     = "us-east-1"
}

# variable "account_emails" {
#   description = "Map of account names to email addresses"
#   type        = map(string)
#   sensitive   = true
# }

# OU variables
variable "organization_id" {
  description = "AWS Organizations ID"
  type        = string
  default     = ""
}

variable "accounts_list" {
  description = "List of accounts in the organization"
  type = map(object({
    name = string
  }))
}

# Environment variables
variable "environment_tags" {
  description = "Valid environment tag values"
  type        = list(string)
  default     = ["dev", "prod"]
}

variable "waiting_period_days" {
  description = "Number of days to wait before deleting an key"
  type        = number
  default     = 30
}

# Templates paths for policies
variable "tpl_scp_path" {
  description = "Path to SCP templates"
  type        = string
  default     = "templates/policies/scps"
}

variable "tag_enforcement_policy" {
  description = "File path for tag enforcement policy"
  type        = string
  default     = "tag_enforcement.json.tftpl"
}

variable "waiting_period_policy" {
  description = "File path for waiting period policy"
  type        = string
  default     = "waiting_period.json.tftpl"
}

variable "env_enforcement_policy" {
  description = "File path for environment enforcement policy"
  type        = string
  default     = "env-enforcement.json.tftpl"
}

variable "kms_admin_policy" {
  description = "File path for KMS admin policy"
  type        = string
  default     = "kms_admin_policy.json.tftpl"
}
