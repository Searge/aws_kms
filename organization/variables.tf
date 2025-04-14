variable "aws_region" {
  description = "AWS region for the organization management account"
  type        = string
  default     = "us-east-1"
}

variable "environment_tags" {
  description = "Valid environment tag values"
  type        = list(string)
  default     = ["dev", "test", "stage", "prod"]
}
