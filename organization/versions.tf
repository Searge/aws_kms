terraform {
  # Required Terraform version
  required_version = ">= 1.10"
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
provider "aws" {
  region = var.aws_region
}
