variable "vpc_cidr" {
  type = string
}

variable "aws_assume_role_arn" {
  type = string
}

variable "module_vpc" {
  type    = bool
  default = false
}

variable "module_ecr" {
  type    = bool
  default = false
}

variable "module_msk" {
  type    = bool
  default = false
}

variable "module_ecs" {
  type    = bool
  default = false
}


variable "module_lambda" {
  type    = bool
  default = false
}
