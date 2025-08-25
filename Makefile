ENVS = local dev prod
CMDS = init plan apply destroy output
# 環境とterraformコマンドの組み合わせを作成する
# ENVSをforeachでenvに格納し、addprefix関数でCMDSにenv-を付与する
TARGETS = $(foreach env, $(ENVS), $(addprefix $(env)-, $(CMDS) ))
# tgプレフィックス付きのターゲットを作成
TG_TARGETS := $(foreach env,$(ENVS),$(addprefix tg-$(env)-,$(CMDS)))

.PHONY: $(TARGETS) $(TG_TARGETS)
## 通常のターゲット (`local-init`, `dev-plan` など)
%-%: # ターゲットのパターンマッチをハイフン区切りで作成する
# subst関数で-を空白に置き換え1つ目と2つ目をそれぞれ代入
	@ENV=$(word 1,$(subst -, ,$@)); \
	CMD=$(word 2,$(subst -, ,$@)); \
	echo "--- 🛠️ Running 'terraform $$CMD' for environment: '$$ENV' ---"; \
	cd terraform/environments/$$ENV && terraform $$CMD

## `tg-` プレフィックス付きターゲット (`tg-local-init`, `tg-dev-plan` など)
tg-%-%:
	@ENV=$(word 2,$(subst -, ,$@)); \
	CMD=$(word 3,$(subst -, ,$@)); \
	echo "--- 🛠️ Running 'terraform $$CMD' with TG for environment: '$$ENV' ---"; \
	cd terraform/environments/$$ENV && terraform $$CMD

# 共通ルートモジュール設計用
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

# segment毎に分離設計用
# local-foundation
.PHONY: local-foundation-init local-foundation-plan local-foundation-apply local-foundation-destroy local-foundation-output
local-foundation-init:
	cd terraform/segments/foundation/environments/local && terraform init
local-foundation-plan:
	cd terraform/segments/foundation/environments/local && terraform plan
local-foundation-apply:
	cd terraform/segments/foundation/environments/local && terraform apply
local-foundation-destroy:
	cd terraform/segments/foundation/environments/local && terraform destroy
local-foundation-output:
	cd terraform/segments/foundation/environments/local && terraform output

# local-application
.PHONY: local-application-init local-application-plan local-application-apply local-application-destroy local-application-output
local-application-init:
	cd terraform/segments/application/environments/local && terraform init
local-application-plan:
	cd terraform/segments/application/environments/local && terraform plan
local-application-apply:
	cd terraform/segments/application/environments/local && terraform apply
local-application-destroy:
	cd terraform/segments/application/environments/local && terraform destroy
local-application-output:
	cd terraform/segments/application/environments/local && terraform output

# local-data-processing
.PHONY: local-data-processing-init local-data-processing-plan local-data-processing-apply local-data-processing-destroy local-data-processing-output
local-data-processing-init:
	cd terraform/segments/data-processing/environments/local && terraform init
local-data-processing-plan:
	cd terraform/segments/data-processing/environments/local && terraform plan
local-data-processing-apply:
	cd terraform/segments/data-processing/environments/local && terraform apply
local-data-processing-destroy:
	cd terraform/segments/data-processing/environments/local && terraform destroy
local-data-processing-output:
	cd terraform/segments/data-processing/environments/local && terraform output

# terragrunt local foundation
.PHONY: tg-local-foundation-init tg-local-foundation-plan tg-local-foundation-apply tg-local-foundation-destroy tg-local-foundation-output
tg-local-foundation-init: 
	cd terraform/segments/foundation/environments/local && terragrunt init
tg-local-foundation-plan: 
	cd terraform/segments/foundation/environments/local && terragrunt plan
tg-local-foundation-apply: 
	cd terraform/segments/foundation/environments/local && terragrunt apply
tg-local-foundation-destroy: 
	cd terraform/segments/foundation/environments/local && terragrunt destroy
tg-local-foundation-output: 
	cd terraform/segments/foundation/environments/local && terragrunt output

# terragrunt local application
.PHONY: tg-local-application-init tg-local-application-plan tg-local-application-apply tg-local-application-destroy tg-local-application-output
tg-local-application-init: 
	cd terraform/segments/application/environments/local && terragrunt init
tg-local-application-plan: 
	cd terraform/segments/application/environments/local && terragrunt plan
tg-local-application-apply: 
	cd terraform/segments/application/environments/local && terragrunt apply
tg-local-application-destroy: 
	cd terraform/segments/application/environments/local && terragrunt destroy
tg-local-application-output: 
	cd terraform/segments/application/environments/local && terragrunt output

# terragrunt local data-processing
.PHONY: tg-local-data-processing-init tg-local-data-processing-plan tg-local-data-processing-apply tg-local-data-processing-destroy tg-local-data-processing-output
tg-local-data-processing-init: 
	cd terraform/segments/data-processing/environments/local && terragrunt init
tg-local-data-processing-plan: 
	cd terraform/segments/data-processing/environments/local && terragrunt plan
tg-local-data-processing-apply: 
	cd terraform/segments/data-processing/environments/local && terragrunt apply
tg-local-data-processing-destroy: 
	cd terraform/segments/data-processing/environments/local && terragrunt destroy
tg-local-data-processing-output: 
	cd terraform/segments/data-processing/environments/local && terragrunt output