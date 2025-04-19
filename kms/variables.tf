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

variable "env" {
  type        = string
  description = "Environment name"
}

variable "project" {
  description = "Project name"
  type        = string
  default = ""
}

variable "tags" {
  description = "The map of tags"
  type        = map(string)
  default     = {}
}
