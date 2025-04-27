terraform {
  required_version = "1.11.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.96.0"
    }
  }

  backend "s3" {
    role_arn       = "arn:aws:iam::064855577434:role/terraform-apply-development"
  }
}

provider "aws" {
  #allowed_account_ids = [""]
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::064855577434:role/terraform-apply-development"
  }
  default_tags {
    tags = {
      project-name = "fml"
      environment  = "development"
      Terraform    = "true"
    }
  }
}
