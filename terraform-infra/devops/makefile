# Makefile for Terraform bootstrap process

.PHONY: bootstrap help

# Configuration
ENV             ?= development
AWS_PROFILE     ?= default

help:
	@echo "Terraform Bootstrap Targets:"
	@echo "  bootstrap - Setup Local Backend for environment"
	@echo "  plan      - Generate execution plan"
	@echo "  apply     - Apply changes"
	@echo "  destroy   - Destroy infrastructure"
	@echo "  clean     - Remove temporary files"
	@echo ""
	@echo "Variables:"
	@echo "  ENV=env           Set environment (default: develoment)"
	@echo "  AWS_PROFILE=name  Set AWS profile (default: default)"

bootstrap:
	@echo "Running bootstrap for $(ENV) environment..."
	@chmod +x bootstrap.sh
	AWS_PROFILE=$(AWS_PROFILE) ENVIRONMENT=$(ENV) ./bootstrap.sh 2>&1 | tee $(BOOTSTRAP_LOG)
	@echo "Bootstrap complete. Log saved to $(BOOTSTRAP_LOG)"
