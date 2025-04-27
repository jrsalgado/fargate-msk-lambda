terraform {
  required_version = "1.11.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.96.0"
    }
  }

  backend "s3" {
    # Configuration will be provided by backend.hcl
    role_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/terraform-apply-development"
  }
}

provider "aws" {
  alias    = "development"
  region   = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/terraform-apply-development"
  }
}
