terraform {
  required_version = "1.11.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.96.0"
    }
  }

  backend "s3" {
    role_arn = var.aws_assume_role_arn
  }
}

provider "aws" {
  #allowed_account_ids = [""]
  region = "us-east-1"
  assume_role {
    role_arn = var.aws_assume_role_arn
  }
  default_tags {
    tags = {
      project-name = "fml"
      environment  = "development"
      Terraform    = "true"
    }
  }
}
