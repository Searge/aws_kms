variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "aws_access_key_id" {
  type        = string
  description = "AWS access key ID"
}

variable "aws_secret_access_key" {
  type        = string
  description = "AWS secret access key"
}

# Organizational Units
variable "ou_map" {
  type = map(any)
  default = {
    "dev"  = "/root/dev/*"
    "prod" = "/root/prod/*"
  }
}

# Accounts
variable "accounts_list" {
  description = "List of accounts in the organization"
  type = map(object({
    name       = string
    email      = string
    account_id = string
    tags       = map(string)
  }))
}

# Policies
variable "policy_type" {
  type    = string
  default = "SERVICE_CONTROL_POLICY"
  validation {
    condition = contains([
      "AISERVICES_OPT_OUT_POLICY",
      "BACKUP_POLICY",
      "RESOURCE_CONTROL_POLICY",
      "SERVICE_CONTROL_POLICY",
      "TAG_POLICY"
    ], var.policy_type)
    error_message = "unsupported policy type"
  }
}

variable "policies_directory" {
  type    = string
  default = "policies"
}
