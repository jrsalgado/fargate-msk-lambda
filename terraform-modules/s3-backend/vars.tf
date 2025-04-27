variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "enable_force_destroy" {
  description = "Allow bucket to be destroyed with contents (for testing)"
  type        = bool
  default     = false
}

variable "additional_terraform_permissions" {
  description = "Additional permissions to attach to the Terraform role"
  type        = list(string)
  default     = []
}
