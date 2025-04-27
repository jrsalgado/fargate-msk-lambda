variable "environment" {
  type    = string
  default = "development"
}

variable "aws_profile" {
  type      = string
  default   = null
  sensitive = true
}

variable "aws_assume_role_arn" {
  type = string
}