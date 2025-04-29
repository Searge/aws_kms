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

variable "environment_name" {}

variable "tags" {}

###############################################################################
# KMS Policy Options
###############################################################################
variable "enable_key_rotation" {
  description = "Enable automatic key rotation"
  type        = bool
  default     = true
}

variable "deletion_window_in_days" {
  description = "Duration in days after which the key is deleted after destruction of the resource"
  type        = number
  default     = 7
}

variable "additional_policy_statements" {
  description = "Additional policy statements to include in the KMS key policy"
  type = list(object({
    sid        = string
    effect     = string
    principals = map(list(string))
    actions    = list(string)
    resources  = list(string)
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }))
  default = []
}

###############################################################################
# KMS Naming conventions
###############################################################################
variable "key_function" {
  description = "Function of the KMS key (e.g., db, api)"
  type        = string
  default     = "aws"
}

variable "key_team" {
  description = "Team responsible for the KMS key (e.g., payments, ml)"
  type        = string
  default     = ""
}

variable "key_purpose" {
  description = "Purpose of the KMS key (e.g., encryption, tokenization)"
  type        = string
  default     = "cmk"
}

###############################################################################
# Policy paths
###############################################################################
variable "policy_file" {
  description = "Filename for a specific KMS policy file in the policies directory"
  type        = string
  default     = ""
}
