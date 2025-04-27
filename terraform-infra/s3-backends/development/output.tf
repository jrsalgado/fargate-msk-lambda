output "backend_config_bucket" {
  value = module.terraform_backend.backend_config_bucket
}

output "backend_config_role_arn" {
  value = module.terraform_backend.backend_config_role_arn
}