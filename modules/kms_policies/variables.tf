###############################################################################
# Project
###############################################################################
variable "project" {
  description = "Project name for deployment"
  type        = string

  validation {
    condition     = length(var.project) >= 3 && var.project != null && var.project != ""
    error_message = "Error: Incorrect project name."
  }
}

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
