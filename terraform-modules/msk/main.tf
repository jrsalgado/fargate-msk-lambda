variable "environment" {}
variable "vpc_id" {}
variable "vpc_private_subnets" {}
variable "vpc_private_subnets_cidr_blocks" {}

locals {
  name = "fml-msk-${var.environment}"
}

module "msk_serverless" {
  source  = "terraform-aws-modules/msk-kafka-cluster/aws//modules/serverless"
  version = "2.11.1" # Use latest version
  name    = local.name

  security_group_ids = [module.msk_sg.security_group_id]
  subnet_ids         = var.vpc_private_subnets

  create_cluster_policy = true
  cluster_policy_statements = {
    ecs_access = {
      sid = "ECSAccess"
      principals = [
        {
          type        = "Service"
          identifiers = ["ecs-tasks.amazonaws.com"]
        }
      ]
      actions = [
        "kafka:GetBootstrapBrokers",
        "kafka:DescribeCluster",
        "kafka:DescribeClusterV2"
      ]
    }
  }
}

module "msk_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name}-sg"
  description = "MSK Serverless security group"
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = [{
    from_port   = 9098
    to_port     = 9098
    protocol    = "tcp"
    description = "ECS to MSK"
    cidr_blocks = join(",", var.vpc_private_subnets_cidr_blocks)
  }]

  egress_rules = ["all-all"]
}

# Only these two outputs are available from the serverless module
output "serverless_arn" {
  value = module.msk_serverless.serverless_arn
}

output "serverless_cluster_uuid" {
  value = module.msk_serverless.serverless_cluster_uuid
}

# Additional outputs we'll create ourselves
output "security_group_id" {
  value = module.msk_sg.security_group_id
}

output "cluster_name" {
  value = local.name
}