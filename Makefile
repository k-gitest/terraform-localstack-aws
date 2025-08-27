# 環境とコマンドの設定
ENVS = local dev prod
CMDS = init plan apply destroy output
# 環境とterraformコマンドの組み合わせを作成する
# ENVSをforeachでenvに格納し、addprefix関数でCMDSにenv-を付与する
TARGETS = $(foreach env, $(ENVS), $(addprefix $(env)-, $(CMDS) ))

.PHONY: $(TARGETS)
## 通常のターゲット (`local-init`, `dev-plan` など)
%-%: # ターゲットのパターンマッチをハイフン区切りで作成する
# subst関数で-を空白に置き換え1つ目と2つ目をそれぞれ代入
	@ENV=$(word 1,$(subst -, ,$@)); \
	CMD=$(word 2,$(subst -, ,$@)); \
	echo "--- 🛠️ Running 'terraform $$CMD' for environment: '$$ENV' ---"; \
	cd terraform/environments/$$ENV && terraform $$CMD

# セグメント定義
SEGMENTS = foundation application data_processing
# セグメント別のターゲット作成 (segment-env-cmd)
SEGMENT_TARGETS = $(foreach segment, $(SEGMENTS), $(foreach env, $(ENVS), $(addprefix $(segment)-$(env)-, $(CMDS))))
.PHONY: $(SEGMENT_TARGETS)
## 個別セグメント実行 (foundation-dev-plan など)
$(SEGMENT_TARGETS):
	@SEGMENT=$(word 1,$(subst -, ,$@)); \
	ENV=$(word 2,$(subst -, ,$@)); \
	CMD=$(word 3,$(subst -, ,$@)); \
	echo "--- 🛠️ Running 'terraform $$CMD' for segment: '$$SEGMENT' environment: '$$ENV' ---"; \
	cd terraform/segments/$$SEGMENT/environments/$$ENV && terraform $$CMD


# TerragruntプロジェクトのMakefile
# セグメント、環境、コマンドの組み合わせのターゲットを生成
TERRAGRUNT_TARGETS = $(foreach segment, $(SEGMENTS), $(foreach env, $(ENVS), $(addprefix tg-$(segment)-$(env)-, $(CMDS))))

# 各セグメントの個別モジュールを定義
FOUNDATION_MODULES = network rds ecr ecs
APPLICATION_MODULES = alb amplify fargate s3__frontend s3__profile_pictures cloudfront__frontend cloudfront__profile_pictures
DATA_PROCESSING_MODULES = lambda

# 個別モジュールのターゲットを生成 (例: foundation-dev-network-plan)
FOUNDATION_MODULE_TARGETS = $(foreach env, $(ENVS), $(foreach module, $(FOUNDATION_MODULES), $(addprefix tg-foundation-$(env)-$(module)-, $(CMDS))))
APPLICATION_MODULE_TARGETS = $(foreach env, $(ENVS), $(foreach module, $(APPLICATION_MODULES), $(addprefix tg-application-$(env)-$(module)-, $(CMDS))))
DATA_PROCESSING_MODULE_TARGETS = $(foreach env, $(ENVS), $(foreach module, $(DATA_PROCESSING_MODULES), $(addprefix tg-data_processing-$(env)-$(module)-, $(CMDS))))

ALL_MODULE_TARGETS = $(FOUNDATION_MODULE_TARGETS) $(APPLICATION_MODULE_TARGETS) $(DATA_PROCESSING_MODULE_TARGETS)

# run-all 用ターゲット (例: foundation-dev-plan-all)
RUN_ALL_TARGETS = $(foreach env, $(ENVS), $(foreach segment, $(SEGMENTS), $(addprefix tg-$(segment)-$(env)-, $(addsuffix -all, $(CMDS)))))

.PHONY: $(TERRAGRUNT_TARGETS) $(ALL_MODULE_TARGETS) $(RUN_ALL_TARGETS)

# 特定のセグメントと環境に対してterragruntコマンドを実行
tg-%-%-%:
	@SEGMENT=$(word 2,$(subst -, ,$@)); \
	ENV=$(word 3,$(subst -, ,$@)); \
	CMD=$(word 4,$(subst -, ,$@)); \
	echo "--- 🛠️ Running 'terragrunt $$CMD' for segment: '$$SEGMENT' and environment: '$$ENV' ---"; \
	cd terraform/live/$$ENV/$$SEGMENT && terragrunt $$CMD

# 特定のモジュールに対してterragruntコマンドを実行
tg-%-%-%-%:
	@SEGMENT=$(word 2,$(subst -, ,$@)); \
	ENV=$(word 3,$(subst -, ,$@)); \
	MODULE=$(word 4,$(subst -, ,$@)); \
	MODULE_PATH=$(subst __,/,$$MODULE); \
	CMD=$(word 5,$(subst -, ,$@)); \
	echo "--- 🛠️ Running 'terragrunt $$CMD' for module: '$$MODULE' in environment: '$$ENV' ---"; \
	cd terraform/live/$$ENV/$$SEGMENT/$$MODULE_PATH && terragrunt $$CMD

# run-all 実行ルール
tg-%-%-%-all:
	@SEGMENT=$(word 2,$(subst -, ,$@)); \
	ENV=$(word 3,$(subst -, ,$@)); \
	CMD=$(word 4,$(subst -, ,$@)); \
	echo "--- 🚀 Running 'terragrunt run-all $$CMD' for segment: '$$SEGMENT' and environment: '$$ENV' ---"; \
	cd terraform/live/$$ENV/$$SEGMENT && terragrunt run-all $$CMD


### **Terraformターゲット**

#### **環境別ターゲット**
* `local-init`
* `local-plan`
* `local-apply`
* `local-destroy`
* `local-output`
* `dev-init`
* `dev-plan`
* `dev-apply`
* `dev-destroy`
* `dev-output`
* `prod-init`
* `prod-plan`
* `prod-apply`
* `prod-destroy`
* `prod-output`

#### **セグメント別ターゲット**
* `foundation-local-init`
* `foundation-local-plan`
* `foundation-local-apply`
* `foundation-local-destroy`
* `foundation-local-output`
* `foundation-dev-init`
* `foundation-dev-plan`
* `foundation-dev-apply`
* `foundation-dev-destroy`
* `foundation-dev-output`
* `foundation-prod-init`
* `foundation-prod-plan`
* `foundation-prod-apply`
* `foundation-prod-destroy`
* `foundation-prod-output`
* `application-local-init`
* `application-local-plan`
* `application-local-apply`
* `application-local-destroy`
* `application-local-output`
* `application-dev-init`
* `application-dev-plan`
* `application-dev-apply`
* `application-dev-destroy`
* `application-dev-output`
* `application-prod-init`
* `application-prod-plan`
* `application-prod-apply`
* `application-prod-destroy`
* `application-prod-output`
* `data_processing-local-init`
* `data_processing-local-plan`
* `data_processing-local-apply`
* `data_processing-local-destroy`
* `data_processing-local-output`
* `data_processing-dev-init`
* `data_processing-dev-plan`
* `data_processing-dev-apply`
* `data_processing-dev-destroy`
* `data_processing-dev-output`
* `data_processing-prod-init`
* `data_processing-prod-plan`
* `data_processing-prod-apply`
* `data_processing-prod-destroy`
* `data_processing-prod-output`

---

### **Terragruntターゲット**

#### **セグメント別ターゲット**
* `foundation-local-init`
* `foundation-local-plan`
* `foundation-local-apply`
* `foundation-local-destroy`
* `foundation-local-output`
* `foundation-dev-init`
* `foundation-dev-plan`
* `foundation-dev-apply`
* `foundation-dev-destroy`
* `foundation-dev-output`
* `foundation-prod-init`
* `foundation-prod-plan`
* `foundation-prod-apply`
* `foundation-prod-destroy`
* `foundation-prod-output`
* `application-local-init`
* `application-local-plan`
* `application-local-apply`
* `application-local-destroy`
* `application-local-output`
* `application-dev-init`
* `application-dev-plan`
* `application-dev-apply`
* `application-dev-destroy`
* `application-dev-output`
* `application-prod-init`
* `application-prod-plan`
* `application-prod-apply`
* `application-prod-destroy`
* `application-prod-output`
* `data_processing-local-init`
* `data_processing-local-plan`
* `data_processing-local-apply`
* `data_processing-local-destroy`
* `data_processing-local-output`
* `data_processing-dev-init`
* `data_processing-dev-plan`
* `data_processing-dev-apply`
* `data_processing-dev-destroy`
* `data_processing-dev-output`
* `data_processing-prod-init`
* `data_processing-prod-plan`
* `data_processing-prod-apply`
* `data_processing-prod-destroy`
* `data_processing-prod-output`

#### **個別モジュールターゲット**
* **Foundation:**
    * `foundation-local-network-init`
    * `foundation-local-network-plan`
    * `foundation-local-network-apply`
    * `foundation-local-network-destroy`
    * `foundation-local-network-output`
    * `foundation-local-rds-init`
    * `foundation-local-rds-plan`
    * `foundation-local-rds-apply`
    * `foundation-local-rds-destroy`
    * `foundation-local-rds-output`
    * `foundation-local-ecr-init`
    * `foundation-local-ecr-plan`
    * `foundation-local-ecr-apply`
    * `foundation-local-ecr-destroy`
    * `foundation-local-ecr-output`
    * `foundation-local-ecs-init`
    * `foundation-local-ecs-plan`
    * `foundation-local-ecs-apply`
    * `foundation-local-ecs-destroy`
    * `foundation-local-ecs-output`
    * ...(dev, prod環境も同様)
* **Application:**
    * `application-local-alb-init`
    * `application-local-alb-plan`
    * `application-local-alb-apply`
    * `application-local-alb-destroy`
    * `application-local-alb-output`
    * `application-local-amplify-init`
    * `application-local-amplify-plan`
    * `application-local-amplify-apply`
    * `application-local-amplify-destroy`
    * `application-local-amplify-output`
    * ...(他のモジュール、dev, prod環境も同様)
* **Data Processing:**
    * `data_processing-local-lambda-init`
    * `data_processing-local-lambda-plan`
    * `data_processing-local-lambda-apply`
    * `data_processing-local-lambda-destroy`
    * `data_processing-local-lambda-output`
    * ...(dev, prod環境も同様)

#### **run-allターゲット**
* `foundation-local-init-all`
* `foundation-local-plan-all`
* `foundation-local-apply-all`
* `foundation-local-destroy-all`
* `foundation-local-output-all`
* `foundation-dev-init-all`
* `foundation-dev-plan-all`
* `foundation-dev-apply-all`
* `foundation-dev-destroy-all`
* `foundation-dev-output-all`
* `foundation-prod-init-all`
* `foundation-prod-plan-all`
* `foundation-prod-apply-all`
* `foundation-prod-destroy-all`
* `foundation-prod-output-all`
* `application-local-init-all`
* `application-local-plan-all`
* `application-local-apply-all`
* `application-local-destroy-all`
* `application-local-output-all`
* `application-dev-init-all`
* `application-dev-plan-all`
* `application-dev-apply-all`
* `application-dev-destroy-all`
* `application-dev-output-all`
* `application-prod-init-all`
* `application-prod-plan-all`
* `application-prod-apply-all`
* `application-prod-destroy-all`
* `application-prod-output-all`
* `data_processing-local-init-all`
* `data_processing-local-plan-all`
* `data_processing-local-apply-all`
* `data_processing-local-destroy-all`
* `data_processing-local-output-all`
* `data_processing-dev-init-all`
* `data_processing-dev-plan-all`
* `data_processing-dev-apply-all`
* `data_processing-dev-destroy-all`
* `data_processing-dev-output-all`
* `data_processing-prod-init-all`
* `data_processing-prod-plan-all`
* `data_processing-prod-apply-all`
* `data_processing-prod-destroy-all`
* `data_processing-prod-output-all`


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