variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}


variable "environment_name" {}

variable "tags" {}

###############################################################################
# KMS Policy Options
###############################################################################
variable "enable_key_rotation" {}

variable "deletion_window_in_days" {}

###############################################################################
# KMS Naming conventions
###############################################################################
variable "key_function" {}

variable "key_team" {}

variable "key_purpose" {}

variable "description" {}

###############################################################################
# Policy paths
###############################################################################
variable "custom_policy" {}

