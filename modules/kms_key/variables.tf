###############################################################################
# Environment
###############################################################################
variable "environment_name" {
  description = "Environment name for deployment"
  type        = string
  #default     = "dev"

  validation {
    condition     = length(var.environment_name) >= 2 && var.environment_name != null && var.environment_name != ""
    error_message = "Error: Incorrect Environment name."
  }
}

###############################################################################
# Tags
###############################################################################
variable "tags" {
  description = "The map of tags"
  type        = map(string)
  default     = {}

  validation {
    condition     = length(var.tags) == 0 || length(var.tags) >= 1
    error_message = "Error: Incorrect mapping was provided to tags."
  }

  validation {
    condition = anytrue(
      [for obj in keys(var.tags) : contains(["owner"], obj)]
    )
    error_message = "Tags map should include owner key string."
  }

  validation {
    condition = anytrue(
      [for obj in keys(var.tags) : contains(["environment"], obj)]
    )
    error_message = "Tags map should include environment key string."
  }

  validation {
    condition = anytrue(
      [for obj in keys(var.tags) : contains(["data-classification"], obj)]
    )
    error_message = "Tags map should include data-classification key string."
  }
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

variable "description" {
  description = "Description of the KMS key"
  type        = string
}

###############################################################################
# Policy paths
###############################################################################
variable "custom_policy" {
  description = "Custom policy file"
  type        = string
  default     = ""
}

################################################################################
# KMS Common Configuration
###############################################################################
variable "enable_key_rotation" {
  description = "Enable automatic key rotation"
  type        = bool
  default     = true
}

###############################################################################
# KMS Policy Options
###############################################################################
variable "deletion_window_in_days" {
  description = "Duration in days after which the key is deleted after destruction of the resource"
  type        = number
  default     = 7
}
