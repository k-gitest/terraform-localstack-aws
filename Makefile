# 環境とコマンドの設定
ENVS := local dev prod
CMDS := init plan apply destroy output
# 環境とterraformコマンドの組み合わせを作成する
# ENVSをforeachでenvに格納し、addprefix関数でCMDSにenv-を付与する
TARGETS := $(foreach env, $(ENVS), $(addprefix $(env)-, $(CMDS) ))

.PHONY: $(TARGETS)

## 通常のターゲット (`local-init`, `dev-plan` など)
%-%: # ターゲットのパターンマッチをハイフン区切りで作成する
# subst関数で-を空白に置き換え1つ目と2つ目をそれぞれ代入
	@ENV=$(word 1,$(subst -, ,$@)); \
	CMD=$(word 2,$(subst -, ,$@)); \
	echo "--- 🛠️ Running 'terraform $$CMD' for environment: '$$ENV' ---"; \
	TARGET_DIR="terraform/environments/$$ENV"; \
	if [ ! -d "$$TARGET_DIR" ]; then \
		echo "❌ Error: Directory $$TARGET_DIR does not exist"; \
		exit 1; \
	fi; \
	cd "$$TARGET_DIR" && terraform $$CMD

# セグメント定義
SEGMENTS := foundation application data_processing
# セグメント別のターゲット作成 (segment-env-cmd)
SEGMENT_TARGETS := $(foreach segment, $(SEGMENTS), $(foreach env, $(ENVS), $(addprefix seg-$(segment)-$(env)-, $(CMDS))))
.PHONY: $(SEGMENT_TARGETS)
## 個別セグメント実行 (seg-foundation-dev-plan など)
seg-%-%-%:
	@SEGMENT=$(word 2,$(subst -, ,$@)); \
	ENV=$(word 3,$(subst -, ,$@)); \
	CMD=$(word 4,$(subst -, ,$@)); \
	echo "--- 🛠️ Running 'terraform $$CMD' for segment: '$$SEGMENT' environment: '$$ENV' ---"; \
	TARGET_DIR="terraform/segments/$$SEGMENT/environments/$$ENV"; \
	if [ ! -d "$$TARGET_DIR" ]; then \
		echo "❌ Error: Directory $$TARGET_DIR does not exist"; \
		exit 1; \
	fi; \
	cd "$$TARGET_DIR" && terraform $$CMD


# TerragruntプロジェクトのMakefile
# セグメント、環境、コマンドの組み合わせのターゲットを生成
TERRAGRUNT_TARGETS := $(foreach segment, $(SEGMENTS), $(foreach env, $(ENVS), $(addprefix tg-$(segment)-$(env)-, $(CMDS))))

# 各セグメントの個別モジュールを定義
FOUNDATION_MODULES := network rds ecr ecs
APPLICATION_MODULES := alb amplify fargate s3__frontend s3__profile_pictures cloudfront__frontend cloudfront__profile_pictures
DATA_PROCESSING_MODULES := lambda

# 個別モジュールのターゲットを生成 (例: foundation-dev-network-plan)
FOUNDATION_MODULE_TARGETS := $(foreach env, $(ENVS), $(foreach module, $(FOUNDATION_MODULES), $(addprefix tg-foundation-$(env)-$(module)-, $(CMDS))))
APPLICATION_MODULE_TARGETS := $(foreach env, $(ENVS), $(foreach module, $(APPLICATION_MODULES), $(addprefix tg-application-$(env)-$(module)-, $(CMDS))))
DATA_PROCESSING_MODULE_TARGETS := $(foreach env, $(ENVS), $(foreach module, $(DATA_PROCESSING_MODULES), $(addprefix tg-data_processing-$(env)-$(module)-, $(CMDS))))

ALL_MODULE_TARGETS := $(FOUNDATION_MODULE_TARGETS) $(APPLICATION_MODULE_TARGETS) $(DATA_PROCESSING_MODULE_TARGETS)

# run-all 用ターゲット (例: foundation-dev-plan-all)
RUN_ALL_TARGETS := $(foreach env, $(ENVS), $(foreach segment, $(SEGMENTS), $(addprefix tg-$(segment)-$(env)-, $(addsuffix -all, $(CMDS)))))

.PHONY: $(TERRAGRUNT_TARGETS) $(ALL_MODULE_TARGETS) $(RUN_ALL_TARGETS)

# run-all 実行ルール (tg-foundation-dev-plan-all など)
tg-%-%-%-all:
	@SEGMENT=$(word 2,$(subst -, ,$@)); \
	ENV=$(word 3,$(subst -, ,$@)); \
	CMD=$(word 4,$(subst -, ,$@)); \
	echo "--- 🚀 Running 'terragrunt run-all $$CMD' for segment: '$$SEGMENT' and environment: '$$ENV' ---"; \
	if [ ! -d "terraform/live/$$ENV/$$SEGMENT" ]; then \
		echo "❌ Error: Directory terraform/live/$$ENV/$$SEGMENT does not exist"; \
		exit 1; \
	fi; \
	cd terraform/live/$$ENV/$$SEGMENT && terragrunt run-all $$CMD --terragrunt-parallelism=1

# 特定のモジュールに対してterragruntコマンドを実行(tg-foundation-dev-network-plan など)
tg-%-%-%-%:
	@SEGMENT=$(word 2,$(subst -, ,$@)); \
	ENV=$(word 3,$(subst -, ,$@)); \
	MODULE=$(word 4,$(subst -, ,$@)); \
	MODULE_PATH=$$(echo "$$MODULE" | sed 's|__|/|g'); \
	CMD=$(word 5,$(subst -, ,$@)); \
	echo "--- 🛠️ Running 'terragrunt $$CMD' for module: '$$MODULE' in environment: '$$ENV' ---"; \
	TARGET_DIR="terraform/live/$$ENV/$$SEGMENT/$$MODULE_PATH"; \
	if [ ! -d "$$TARGET_DIR" ]; then \
		echo "❌ Error: Directory $$TARGET_DIR does not exist"; \
		exit 1; \
	fi; \
	cd "$$TARGET_DIR" && terragrunt $$CMD

# 特定のセグメントと環境に対してterragruntコマンドを実行 (tg-foundation-dev-plan など)
tg-%-%-%:
	@SEGMENT=$(word 2,$(subst -, ,$@)); \
	ENV=$(word 3,$(subst -, ,$@)); \
	CMD=$(word 4,$(subst -, ,$@)); \
	echo "--- 🛠️ Running 'terragrunt $$CMD' for segment: '$$SEGMENT' and environment: '$$ENV' ---"; \
	TARGET_DIR="terraform/live/$$ENV/$$SEGMENT"; \
	if [ ! -d "$$TARGET_DIR" ]; then \
		echo "❌ Error: Directory $$TARGET_DIR does not exist"; \
		exit 1; \
	fi; \
	cd "$$TARGET_DIR" && terragrunt $$CMD


# ヘルプ表示
.PHONY: help list-targets

help:
	@echo "🚀 Terraform/Terragrunt Multi-Configuration Makefile"
	@echo ""
	@echo "📋 Available Commands:"
	@echo ""
	@echo "1️⃣ Standard Terraform (terraform/environments/):"
	@echo "  {env}-{cmd}                    例: local-init, dev-plan, prod-apply"
	@echo ""
	@echo "2️⃣ Segment Terraform (terraform/segments/):"
	@echo "  seg-{segment}-{env}-{cmd}      例: seg-foundation-dev-plan"
	@echo ""
	@echo "3️⃣ Terragrunt run-all (terraform/live/):"
	@echo "  tg-{segment}-{env}-{cmd}-all   例: tg-foundation-dev-plan-all --terragrunt-parallelism=1"
	@echo ""
	@echo "4️⃣ Terragrunt segment (terraform/live/):"
	@echo "  tg-{segment}-{env}-{cmd}       例: tg-foundation-dev-plan"
	@echo ""
	@echo "5️⃣ Terragrunt individual modules:"
	@echo "  tg-{segment}-{env}-{module}-{cmd}  例: tg-foundation-dev-s3__profile_pictures-plan"
	@echo ""
	@echo "📦 Available:"
	@echo "  Environments: $(ENVS)"
	@echo "  Commands: $(CMDS)"
	@echo "  Segments: $(SEGMENTS)"
	@echo ""
	@echo "🔧 Configuration Paths:"
	@echo "  Standard:    terraform/environments/{env}/"
	@echo "  Segments:    terraform/segments/{segment}/environments/{env}/"
	@echo "  Terragrunt:  terraform/live/{env}/{segment}/"
	@echo ""

# 利用可能なターゲット一覧表示
list-targets:
	@echo "📋 Available Targets:"
	@echo ""
	@echo "🏗️ Standard Terraform (terraform/environments/):"
	@for target in $(TARGETS); do echo "  $$target"; done
	@echo ""
	@echo "🧩 Segment Terraform (terraform/segments/):"
	@for target in $(SEGMENT_TARGETS); do echo "  $$target"; done
	@echo ""
	@echo "🌊 Terragrunt Run-All (terraform/live/):"
	@for target in $(RUN_ALL_TARGETS); do echo "  $$target"; done
	@echo ""
	@echo "🎯 Terragrunt Segment (terraform/live/):"
	@for target in $(TERRAGRUNT_TARGETS); do echo "  $$target"; done
	@echo ""
	@echo "🔧 Terragrunt Modules (showing first 15):"
	@for target in $(shell echo "$(ALL_MODULE_TARGETS)" | tr ' ' '\n' | head -15); do echo "  $$target"; done
	@echo "  ... and more"