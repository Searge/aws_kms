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
# variable "ou" {}
variable "ou_map" {
  type = map(any)
  default = {
    "dev"  = "/root/dev/*"
    "prod" = "/root/prod/*"
  }
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

variable "policy_type_list" {
  type = list(string)
  default = [
    "RESOURCE_CONTROL_POLICY",
    "SERVICE_CONTROL_POLICY",
  ]
}

variable "policies_directory" {
  type    = string
  default = "policies"
}
# variable "policies" {}

# variable "policy_id" {}

# variable "policies_directory_name" {}

variable "environment" {
  type    = list(string)
  default = ["dev", "prod"]
}

