#!/bin/bash

  # Enable strict error handling

# Configuration
AWS_PROFILE=${AWS_PROFILE:-default}  # Use default if not set
ENVIRONMENT=${ENVIRONMENT:-development}
STATE_BACKEND="backend.hcl" # Backend config file
TFVARSFILE="terraform.tfvars"
BOOTSTRAP_PROVIDERS="providers.bootstrap.tf"
PROVIDERS_TEMPLATE="providers.tf.s3"
FINAL_PROVIDERS="providers.tf"
LOG_FILE="terraform_apply.log"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Check for providers.tf.s3
if [ -f "${FINAL_PROVIDERS}" ]; then
    echo "Error: ${FINAL_PROVIDERS} already exists. This suggests bootstrap was already run."
    echo "To prevent accidental overwrites, please manually verify and remove this file if you want to re-run bootstrap."
    exit 1
fi

# Initialize with local backend (no remote state yet)
echo "Initializing Terraform with local backend..."
terraform init -reconfigure

# Plan and apply bootstrap infrastructure
echo "Planning bootstrap infrastructure..."
terraform plan \
  -var="aws_profile=${AWS_PROFILE}" \
  -out=tfplan.bootstrap

echo "Applying bootstrap infrastructure..."
echo "Log saved to ${LOG_FILE}.${TIMESTAMP}"

if terraform apply tfplan.bootstrap 2>&1 | tee -a "${LOG_FILE}.${TIMESTAMP}"; then
    echo "Success - apply tfplan.bootstrap"
else
    echo "Apply failed - see ${LOG_FILE}.${TIMESTAMP}"
    exit 1
fi

# If apply succeeds, setup remote backend
echo "Bootstrapping successful. Setting up remote backend..."

# Generate backend configuration from outputs
cat > "${STATE_BACKEND}" <<EOF
bucket            = "$(terraform output -raw backend_config_bucket)"
key               = "terraform-s3-backend.tfstate"
region            = "us-east-1"
use_lockfile      = true
EOF

cat > "${TFVARSFILE}" <<EOF
aws_assume_role_arn = "$(terraform output -raw backend_config_role_arn)"
EOF

# Rotate provider configuration files
if [ -f "${BOOTSTRAP_PROVIDERS}" ]; then
  echo "Disabling bootstrap providers..."
  mv "${BOOTSTRAP_PROVIDERS}" "${BOOTSTRAP_PROVIDERS}.disabled"
fi

if [ -f "${PROVIDERS_TEMPLATE}" ]; then
  echo "Activating final providers configuration..."
  mv "${PROVIDERS_TEMPLATE}" "${FINAL_PROVIDERS}"
fi

# Reinitialize with remote backend
echo "Reinitializing with remote backend..."
terraform init -reconfigure -backend-config="${STATE_BACKEND}"

echo "Bootstrap process completed successfully!"
echo "State is now stored in S3: $(terraform output -raw backend_config_bucket)"