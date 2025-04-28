# terraform-modules/lambda/main.tf
variable "environment" {}
variable "image_uri" {}
variable "msk_cluster_name" {}
variable "msk_security_group_id" {}
variable "vpc_private_subnets" {
  type = list(string)
}

data "aws_msk_cluster" "kafka" {
  cluster_name = var.msk_cluster_name
}


data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "fml-lambda-event-consumer-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "lambda_msk_access" {
  name        = "fml-lambda-msk-access-${var.environment}"
  description = "Allows Lambda to consume from MSK"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kafka:GetBootstrapBrokers",
          "kafka:DescribeCluster",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:ReadData"
        ],
        Resource = [
          data.aws_msk_cluster.kafka.arn,
          "${data.aws_msk_cluster.kafka.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_basic_execution" {
  name       = "lambda-basic-execution"
  roles      = [aws_iam_role.lambda.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy_attachment" "lambda_vpc_access" {
  name       = "lambda-vpc-access"
  roles      = [aws_iam_role.lambda.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy_attachment" "lambda_msk_access" {
  name       = "lambda-msk-access"
  roles      = [aws_iam_role.lambda.name]
  policy_arn = aws_iam_policy.lambda_msk_access.arn
}

resource "aws_lambda_event_source_mapping" "msk_trigger" {
  event_source_arn = data.aws_msk_cluster.kafka.arn
  function_name    = module.lambda_function_container_image.lambda_function_name
  topics           = ["events"]
  starting_position = "LATEST"

  source_access_configuration {
    type = "VPC_SUBNET"
    uri  = join(",", var.vpc_private_subnets)
  }

  source_access_configuration {
    type = "VPC_SECURITY_GROUP"
    uri  = var.msk_security_group_id
  }
}

module "lambda_function_container_image" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "fml-event-consumer-${var.environment}"
  description   = "Consumes events from MSK topic"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  create_package = false
  package_type  = "Image"
  image_uri     = var.image_uri

  vpc_subnet_ids         = var.vpc_private_subnets
  vpc_security_group_ids = [var.msk_security_group_id]
  attach_network_policy  = true

  timeout     = 30
  memory_size = 512

  environment_variables = {
    MSK_CLUSTER_ARN = data.aws_msk_cluster.kafka.arn
    TOPIC_NAME      = "events"
  }

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    MSKTrigger = {
      principal  = "kafka.amazonaws.com"
      source_arn = data.aws_msk_cluster.kafka.arn
    }
  }
}

output "lambda_function_name" {
  value = module.lambda_function_container_image.lambda_function_name
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda.arn
}