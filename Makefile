# Local環境
.PHONY: local-init local-plan local-apply local-destroy local-output
local-init:
	cd terraform/environments/local && terraform init

local-plan:
	cd terraform/environments/local && terraform plan

local-apply:
	cd terraform/environments/local && terraform apply

local-destroy:
	cd terraform/environments/local && terraform destroy

local-output:
	cd terraform/environments/local && terraform output

# Dev環境
.PHONY: dev-init dev-plan dev-apply dev-destroy dev-output
dev-init:
	cd terraform/environments/dev && terraform init

dev-plan:
	cd terraform/environments/dev && terraform plan

dev-apply:
	cd terraform/environments/dev && terraform apply

dev-destroy:
	cd terraform/environments/dev && terraform destroy

dev-output:
	cd terraform/environments/dev && terraform output

# Staging環境
.PHONY: staging-init staging-plan staging-apply staging-destroy staging-output
staging-init:
	cd terraform/environments/staging && terraform init

staging-plan:
	cd terraform/environments/staging && terraform plan

staging-apply:
	cd terraform/environments/staging && terraform apply

staging-destroy:
	cd terraform/environments/staging && terraform destroy

staging-output:
	cd terraform/environments/staging && terraform output

# Production環境
.PHONY: prod-init prod-plan prod-apply prod-destroy prod-output
prod-init:
	cd terraform/environments/prod && terraform init

prod-plan:
	cd terraform/environments/prod && terraform plan

prod-apply:
	cd terraform/environments/prod && terraform apply

prod-destroy:
	cd terraform/environments/prod && terraform destroy

prod-output:
	cd terraform/environments/prod && terraform output