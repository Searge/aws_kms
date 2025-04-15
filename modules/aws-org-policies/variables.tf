variable "policies" {
  description = "Map of policy configurations including template file and variables"
  type = map(object({
    template    = string
    vars        = map(any)
    name        = optional(string)
    description = optional(string)
    type        = optional(string)
    targets     = optional(list(string))
    tags        = optional(map(string))
  }))
}

variable "template_dir" {
  description = "Directory containing the template files"
  type        = string
}

variable "repository_name" {
  description = "Name of the repository managing these resources"
  type        = string
  default     = "infrastructure"
}

variable "service_name" {
  description = "Name of the service these policies govern"
  type        = string
  default     = "AWS"
}
