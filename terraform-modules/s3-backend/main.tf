locals {
  bucket_name = "terraform-state-${data.aws_caller_identity.current.account_id}-${var.environment}"
  table_name  = "terraform-locks-${var.environment}"
  role_name   = "terraform-apply-${var.environment}"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = local.bucket_name
  force_destroy = var.enable_force_destroy

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# IAM Role for Terraform operations
resource "aws_iam_role" "terraform_apply" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    # Allow GitHub Actions to assume this role
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }
  }
}

# Core Terraform permissions
resource "aws_iam_policy" "terraform_base" {
  name        = "terraform-base-${var.environment}"
  description = "Base permissions for Terraform operations"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:List*",
          "s3:Get*",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
      }
    ]
  })
}

# Additional infrastructure permissions
resource "aws_iam_policy" "terraform_infra" {
  name        = "terraform-infra-${var.environment}"
  description = "Permissions for Terraform to manage infrastructure"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:*",
          "ecs:*",
          "lambda:*",
          "kafka:*",
          "ec2:*",
          "logs:*",
          "iam:*",
          "route53:*",
          "rds:*",
          "sns:*",
          "sqs:*"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach policies to the role
resource "aws_iam_role_policy_attachment" "terraform_base" {
  role       = aws_iam_role.terraform_apply.name
  policy_arn = aws_iam_policy.terraform_base.arn
}

resource "aws_iam_role_policy_attachment" "terraform_infra" {
  role       = aws_iam_role.terraform_apply.name
  policy_arn = aws_iam_policy.terraform_infra.arn
}

# DevOps Group
resource "aws_iam_group" "devops" {
  name = "devops-${var.environment}"
}

# Policy to allow assuming the Terraform role
resource "aws_iam_policy" "assume_terraform_role" {
  name        = "assume-terraform-role-${var.environment}"
  description = "Allows assuming the Terraform apply role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "sts:AssumeRole",
      Resource = aws_iam_role.terraform_apply.arn
    }]
  })
}

resource "aws_iam_group_policy_attachment" "devops_assume_role" {
  group      = aws_iam_group.devops.name
  policy_arn = aws_iam_policy.assume_terraform_role.arn
}
