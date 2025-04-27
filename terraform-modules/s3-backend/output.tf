
output "backend_config_bucket" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "backend_config_role_arn" {
  value = aws_iam_role.terraform_apply.arn
}
