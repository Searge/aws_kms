###############################################################################
# Project
###############################################################################
# variable "project" {
#   description = "Project name for deployment"
#   type        = string

#   validation {
#     condition     = length(var.project) >= 3 && var.project != null && var.project != ""
#     error_message = "Error: Incorrect project name."
#   }
# }

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
      [for obj in keys(var.tags) : contains(["BU"], obj)]
    )
    error_message = "Tags map should include BU(Business Unit) key string."
  }

  validation {
    condition = anytrue(
      [for obj in keys(var.tags) : contains(["BusinessOwner"], obj)]
    )
    error_message = "Tags map should include BusinessOwner key string."
  }

  validation {
    condition = anytrue(
      [for obj in keys(var.tags) : contains(["TechnicalOwner"], obj)]
    )
    error_message = "Tags map should include TechnicalOwner key string."
  }

  validation {
    condition = anytrue(
      [for obj in keys(var.tags) : contains(["ProjectManager"], obj)]
    )
    error_message = "Tags map should include ProjectManager key string."
  }

  validation {
    condition = anytrue(
      [for obj in keys(var.tags) : contains(["Project"], obj)]
    )
    error_message = "Tags map should include Project key string."
  }

  validation {
    condition = anytrue(
      [for obj in keys(var.tags) : contains(["Owner"], obj)]
    )
    error_message = "Tags map should include Owner key string."
  }

  validation {
    condition = anytrue(
      [for obj in keys(var.tags) : contains(["Environment"], obj)]
    )
    error_message = "Tags map should include Environment key string."
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

###############################################################################
# Policy paths
###############################################################################
variable "policy_file" {
  description = "Filename for a specific KMS policy file in the policies directory"
  type        = string
  default     = ""
}

################################################################################
# KMS Common Configuration
###############################################################################
variable "enable_key_rotation" {
  description = "Enable automatic key rotation"
  type = bool
  default = true
}

variable "custom_policy" {
  description = "Custom policy for the KMS key. If provided, this will replace the default policy"
  type        = string
  default     = ""
}

###############################################################################
# KMS Policy Options
###############################################################################
variable "enable_prevent_permission_delegation" {
  description = "Enable preventing permission delegation by restricting KMS access to Account principals only"
  type        = bool
  default     = false
}

variable "enable_ou_principals_only" {
  description = "Enable restricting KMS operations to principals from a specific organization"
  type        = bool
  default     = false
}

variable "organization_id" {
  description = "AWS Organization ID for organization-based access restrictions"
  type        = string
  default     = ""
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
