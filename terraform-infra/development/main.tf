module "ecr" {
  count       = var.module_ecr ? 1 : 0
  source      = "../../terraform-modules/ecr"
  environment = "development"
  repository_read_write_access_arns = [
    var.aws_assume_role_arn
  ]
}

module "vpc" {
  count       = var.module_vpc ? 1 : 0
  source      = "../../terraform-modules/vpc"
  environment = "development"
  vpc_cidr    = var.vpc_cidr
}

module "msk" {
  count  = var.module_msk ? 1 : 0
  source = "../../terraform-modules/msk"
}

module "ecs" {
  count  = var.module_ecs ? 1 : 0
  source = "../../terraform-modules/ecs"
}

module "lambda" {
  count  = var.module_lambda ? 1 : 0
  source = "../../terraform-modules/lambda"
}