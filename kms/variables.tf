variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "aws_access_key_id" {
  type        = string
  description = "AWS access key ID"
}

variable "aws_secret_access_key" {
  type        = string
  description = "AWS secret access key"
}
