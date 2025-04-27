
# Network
module "vpc" {
  source = "../../terraform-modules/vpc"
  environment = "development"
  vpc_cidr = "172.16.0.0/16"
}

# TODO: setup ECR
#module "ecr" {
#  source = "../../terraform-modules/ecr"
#}

# TODO: setup KAFKA
#module "msk" {
#  source              = "../../terraform-modules/msk"
#}

# TODO: setup ECS
#module "ecs" {
#  source              = "../../terraform-modules/ecs"
#}

# TODO: setup Lambda
#module "lambda" {
#  source              = "../../terraform-modules/lambda"
#}