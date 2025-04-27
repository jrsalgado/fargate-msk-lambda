locals {
  vpc_name = "fml-vpc-${var.environment}"

  # Calculate subnet CIDRs dynamically based on VPC CIDR
  private_subnets = [for i in range(var.az_count) : 
    cidrsubnet(var.vpc_cidr, 8, i + 1)  # 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24
  ]
  public_subnets = [for i in range(var.az_count) : 
    cidrsubnet(var.vpc_cidr, 8, i + 101)  # 10.0.101.0/24, 10.0.102.0/24, 10.0.103.0/24
  ]
}

variable "environment" {
  default = "development"
}

variable "vpc_cidr" {
  default = "10.1.0.0/16"
}

variable "az_count" {
  default = 3
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
    version = "5.21.0"

  name = local.vpc_name
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  manage_default_security_group = false
}
