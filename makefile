# Makefile for Terraform bootstrap process

.PHONY: bootstrap terraform-init terraform-plan help

# Configuration
ENVIRONMENT     ?= development
AWS_PROFILE     ?= default

help:
	@echo "Terraform Bootstrap Targets:"
	@echo "  bootstrap - Setup Local Backend for environment"
	@echo ""
	@echo "Variables:"
	@echo "  ENV=env           Set environment (default: develoment)"
	@echo "  AWS_PROFILE=name  Set AWS profile (default: default)"

bootstrap:
	@cp -rf terraform-modules/bootrap-backend-tpl terraform-infra/s3-backends/${ENVIRONMENT}
	@cd terraform-infra/s3-backends/${ENVIRONMENT} && \
		ls -la && \
		echo "Running bootstrap for $(ENVIRONMENT) environment..." && \
		AWS_PROFILE=$(AWS_PROFILE) ENVIRONMENT=$(ENVIRONMENT) ./tf-bootstrap.sh 2>&1 | tee $(BOOTSTRAP_LOG)

terraform-init:
	@cd terraform-infra/${ENVIRONMENT} && \
		terraform init -reconfigure -backend-config="backend.hcl"

terraform-plan:
	@cd terraform-infra/${ENVIRONMENT} && \
		terraform plan

terraform-apply:
	@cd terraform-infra/${ENVIRONMENT} && \
		terraform apply