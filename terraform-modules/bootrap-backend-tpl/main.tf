module "terraform_backend" {
  source = "../../../terraform-modules/s3-backend"
  environment = var.environment
  region      = "us-east-1"
  enable_force_destroy = true # Only for non-production
}

data "aws_caller_identity" "current" {}