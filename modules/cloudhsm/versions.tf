terraform {
  # Required Terraform version - align with existing KMS module
  required_version = ">= 1.10"

  required_providers {
    # AWS Provider - align with existing version constraint
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.94"
    }

    # Random provider for generating unique names
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}
