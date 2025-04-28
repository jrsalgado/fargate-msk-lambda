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
  count                           = var.module_msk ? 1 : 0
  source                          = "../../terraform-modules/msk"
  environment                     = "development"
  vpc_id                          = module.vpc[0].vpc_id
  vpc_private_subnets             = module.vpc[0].private_subnets
  vpc_private_subnets_cidr_blocks = module.vpc[0].private_subnets_cidr_blocks
  depends_on                      = [module.vpc]
}

module "ecs" {
  count                 = var.module_ecs ? 1 : 0
  source                = "../../terraform-modules/ecs"
  environment           = "development"
  ecr_repository_url    = module.ecr[0].repository_url
  vpc_private_subnets   = module.vpc[0].private_subnets
  msk_cluster_name      = module.msk[0].cluster_name
  msk_security_group_id = module.msk[0].security_group_id

  depends_on = [module.ecr, module.vpc, module.msk]
}

module "lambda" {
  count       = var.module_lambda ? 1 : 0
  source      = "../../terraform-modules/lambda"
  environment = "development"
  image_uri   = "064855577434.dkr.ecr.us-east-1.amazonaws.com/fml-event-consumer-development:latest"
  msk_security_group_id = module.msk[0].security_group_id
  vpc_private_subnets   = module.vpc[0].private_subnets
  msk_cluster_name      = module.msk[0].cluster_name
  depends_on  = [module.ecr, module.vpc, module.msk]
}