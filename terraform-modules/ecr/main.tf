locals {
  ecr_name = "fml-${var.environment}"
}

variable "environment" {
  default = "development"
}
variable "repository_read_write_access_arns" {
  type = list(string)
}
output "repository_url" {
  value = module.ecr.repository_url
}

module "ecr" {
  source          = "terraform-aws-modules/ecr/aws"
  version         = "v2.4.0"
  repository_name = local.ecr_name

  repository_read_write_access_arns = var.repository_read_write_access_arns
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}