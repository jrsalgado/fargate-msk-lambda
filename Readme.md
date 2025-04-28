# FML (Fargate-MSK-Lambda) Architecture

A serverless event-driven architecture using AWS Fargate, MSK (Managed Streaming for Kafka), and Lambda.

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI v2 installed and configured
- Terraform v1.0+
- Docker
- Python 3.9+
- Make (optional)

## Deployment Process

### 1. Bootstrap Infrastructure

```bash
cd terraform-infra/s3-backends/development
terraform init
terraform apply
```

### 2. Deploy Core Infrastructure
```bash
cd terraform-infra/development
terraform init -backend-config=backend.hcl
terraform apply
```

### 3. Build and Push Application Images
```bash
# Build and push hello-world service
cd apps/hello-world
docker build -t hello-world .
aws ecr get-login-password | docker login --username AWS --password-stdin <ECR_URL>
docker tag hello-world:latest <ECR_URL>/hello-world:latest
docker push <ECR_URL>/hello-world:latest

# Build and push Lambda consumer
cd ../../lambdas/kafka-consumer
docker build -t kafka-consumer .
docker tag kafka-consumer:latest <ECR_URL>/kafka-consumer:latest
docker push <ECR_URL>/kafka-consumer:latest
```


### 4. Deploy Services
```bash
cd ../../terraform-infra/development
terraform apply -target=module.ecs -target=module.lambda
```

## CI/CD Pipeline

On merge to main:

Build and push Docker images

Trigger Terraform deployments

Update ECS service and Lambda function