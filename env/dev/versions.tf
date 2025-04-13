terraform {
  required_providers {
    # AWS Provider
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.94"
    }
    # Required Terraform version
    required_version = ">= 1.10.0"
  }
}