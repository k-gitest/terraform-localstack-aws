# ===================================
# Systems Manager Parameter Store関連（環境分離・セキュリティ強化版）
# ===================================

locals {
  # 環境ごとに ARN リストを生成する関数 (パラメータパスベース)
  ssm_parameter_arn = {
    for env in ["dev", "prod"]:
    env => "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/${env}/*"
  }

  # ===================================
  # 開発環境専用ステートメント（devパスへのフル管理）
  # ===================================
  ssm_dev_management_statements = [
    # パラメータ読み取り操作（Get*）
    {
      Sid    = "SSMGetParametersDev"
      Effect = "Allow"
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ]
      Resource = [
        local.ssm_parameter_arn["dev"]
      ]
    },

    # パラメータ書き込み・変更・削除操作（フル管理）
    {
      Sid    = "SSMModifyParametersDev"
      Effect = "Allow"
      Action = [
        "ssm:PutParameter",
        "ssm:UpdateParameter",
        "ssm:DeleteParameter", # 開発環境は削除可能
        "ssm:DeleteParameters"
      ]
      Resource = [
        local.ssm_parameter_arn["dev"]
      ]
    },

    # パラメータのタグ付け/解除操作
    {
      Sid    = "SSMTaggingDev"
      Effect = "Allow"
      Action = [
        "ssm:AddTagsToResource",
        "ssm:RemoveTagsFromResource",
        "ssm:ListTagsForResource"
      ]
      Resource = [
        local.ssm_parameter_arn["dev"]
      ]
    }
  ]
  
  # ===================================
  # 本番環境専用ステートメント（prodパスへの作成・変更のみ）
  # ===================================
  ssm_prod_management_statements = [
    # パラメータ読み取り操作（Get*）
    {
      Sid    = "SSMGetParametersProd"
      Effect = "Allow"
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ]
      Resource = [
        local.ssm_parameter_arn["prod"]
      ]
    },

    # パラメータ書き込み・変更操作（削除除外）
    {
      Sid    = "SSMModifyParametersProd"
      Effect = "Allow"
      Action = [
        "ssm:PutParameter",
        "ssm:UpdateParameter"
        # "ssm:DeleteParameter", # ❌ 除外
        # "ssm:DeleteParameters" # ❌ 除外
      ]
      Resource = [
        local.ssm_parameter_arn["prod"]
      ]
    },

    # パラメータのタグ付け/解除操作
    {
      Sid    = "SSMTaggingProd"
      Effect = "Allow"
      Action = [
        "ssm:AddTagsToResource",
        "ssm:RemoveTagsFromResource",
        "ssm:ListTagsForResource"
      ]
      Resource = [
        local.ssm_parameter_arn["prod"]
      ]
    }
  ]
  
  # ===================================
  # Local環境専用ステートメント
  # ===================================
  ssm_local_management_statements = local.ssm_dev_management_statements

  # ===================================
  # 環境別ポリシーステートメントのマッピング
  # ===================================
  policy_statements_ssm = {
    local = local.ssm_local_management_statements,
    dev   = local.ssm_dev_management_statements,
    prod  = local.ssm_prod_management_statements,
    # デフォルト（フォールバック）
    default = local.ssm_dev_management_statements
  }
}

# ===================================
# デバッグ用出力
# ===================================

output "ssm_policy_statement_counts" {
  description = "各環境のSSMポリシーのステートメント数"
  value = {
    for env, statements in local.policy_statements_ssm :
    env => length(statements)
  }
}

output "ssm_policy_summary" {
  description = "各環境のSSMポリシー概要"
  value = {
    local   = "Local環境用 - ${var.project_name}/dev/*パスへのフル管理権限"
    dev     = "開発環境用 - ${var.project_name}/dev/*パスへのフル管理権限（削除可）"
    prod    = "本番環境用 - ${var.project_name}/prod/*パスへの読み取り、作成・更新権限のみ（削除不可）"
    default = "デフォルト（開発環境と同等）"
  }
}