terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket  = "<bucket-name>"
    key     = "serverless-cert-approval/terraform.tfstate"
    region  = "<region>"
    profile = "<profile>"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "atlantis"

  default_tags {
    tags = {
      Project     = "Serverless-Certification-Approval"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
