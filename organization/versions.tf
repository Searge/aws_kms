terraform {
  # Required Terraform version
  required_version = "~> 1.11"
  required_providers {
    # AWS Provider
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.94"
    }
  }
  backend "local" {
    path = "./terraform.tfstate"
  }
}
