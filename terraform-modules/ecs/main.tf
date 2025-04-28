variable "environment" {}
variable "region" {
  default = "us-east-1"
}
variable "ecr_repository_url" {}
variable "vpc_private_subnets" {}
variable "msk_cluster_name" {}
variable "msk_security_group_id" {}

locals {
  name = "fml-cluster-${var.environment}"
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.0"

  cluster_name = local.name

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  services = {
    hello_world = {
      cpu    = 256
      memory = 512
      deployment_circuit_breaker = {
        enable   = true
        rollback = true
      }

      # Container definition
      container_definitions = {
        hello_world = {
          essential = true
          image     = "${var.ecr_repository_url}:latest"
          port_mappings = [
            {
              containerPort = 8000
              hostPort      = 8000
              protocol      = "tcp"
            }
          ]
          environment = [
            {
              name  = "MSK_CLUSTER_NAME",
              value = var.msk_cluster_name
            },
            {
              name  = "KAFKA_EVENTS_TOPIC",
              value = "events"
            },
            {
              name  = "ENVIRONMENT"
              value = var.environment
            }
          ]
        }
      }
      # Networking
      subnet_ids = var.vpc_private_subnets
    }
  }


}
