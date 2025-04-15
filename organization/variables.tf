variable "aws_region" {
  description = "AWS region for the organization management account"
  type        = string
  default     = "us-east-1"
}

# OU variables
variable "organization_id" {
  description = "AWS Organizations ID"
  type        = string
  default     = ""
}

variable "dev_account_id" {
  description = "Account ID for Arena (dev)"
  type        = string
  sensitive   = true
}

variable "dev_account_email" {
  description = "Email for Arena account"
  type        = string
  sensitive   = true
}

variable "prod_account_id" {
  description = "Account ID for Browbeat (prod)"
  type        = string
  sensitive   = true
}

variable "prod_account_email" {
  description = "Email for Browbeat account"
  type        = string
  sensitive   = true
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
variable "env_enforcement_policy" {
  description = "File path for environment enforcement policy"
  type        = string
  default     = "env-enforcement.json.tftpl"
}

variable "tag_enforcement_policy" {
  description = "File path for tag enforcement policy"
  type        = string
  default     = "tag-enforcement.json.tftpl"
}

variable "waiting_period_policy" {
  description = "File path for waiting period policy"
  type        = string
  default     = "waiting-period.json.tftpl"
}
