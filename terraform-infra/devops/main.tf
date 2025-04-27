module "dev_terraform_backend" {
  source = "../../terraform-modules/bootstrap-backend"
  environment = "development"
  region      = "us-east-1"
  enable_force_destroy = true # Only for non-production
  providers = {
    aws = aws.development
  }
}
