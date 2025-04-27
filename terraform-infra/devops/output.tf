output "backend_config_bucket" {
  value = module.dev_terraform_backend.backend_config_bucket
}

output "backend_config_region" {
  value = module.dev_terraform_backend.backend_config_region
}

output "backend_config_dynamodb_table" {
  value = module.dev_terraform_backend.backend_config_dynamodb_table
}

output "backend_config_role_arn" {
  value = module.dev_terraform_backend.backend_config_role_arn
}