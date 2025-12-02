# ===================================
# STS (Security Token Service) 関連ポリシー定義（環境分離・セキュリティ強化版）
# ===================================

locals {
  # プロジェクトおよび環境固有のロールARNパターンを生成
  assume_role_arn = {
    for env in ["dev", "prod"]:
    env => "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${env}-*"
  }

  # ===================================
  # 共通ステートメント（アカウント情報取得）
  # ===================================
  sts_common_statements = [
    # アカウント情報取得 (必須)
    {
      Sid    = "GetCallerIdentity"
      Effect = "Allow"
      Action = ["sts:GetCallerIdentity"]
      Resource = "*" # STSの仕様上 "*" 必須
    }
  ]
  
  # ===================================
  # 開発環境専用ステートメント（devロールへの AssumeRole 許可）
  # ===================================
  sts_dev_management_statements = [
    # プロジェクトおよび開発環境のロール引き受けを許可
    {
      Sid    = "AssumeRoleDev"
      Effect = "Allow"
      Action = ["sts:AssumeRole"]
      Resource = [
        local.assume_role_arn["dev"]
      ]
    }
  ]
  
  # ===================================
  # 本番環境専用ステートメント（prodロールへの AssumeRole 許可）
  # ===================================
  sts_prod_management_statements = [
    # プロジェクトおよび本番環境のロール引き受けを許可
    {
      Sid    = "AssumeRoleProd"
      Effect = "Allow"
      Action = ["sts:AssumeRole"]
      Resource = [
        local.assume_role_arn["prod"]
      ]
    }
  ]
  
  # ===================================
  # Local環境専用ステートメント
  # ===================================
  sts_local_management_statements = local.sts_dev_management_statements

  # ===================================
  # 環境別ポリシーステートメントのマッピング
  # ===================================
  policy_statements_sts = {
    local = concat(
      local.sts_common_statements,
      local.sts_local_management_statements
    ),
    dev = concat(
      local.sts_common_statements,
      local.sts_dev_management_statements
    ),
    prod = concat(
      local.sts_common_statements,
      local.sts_prod_management_statements
    ),
    # デフォルト（フォールバック）
    default = concat(
      local.sts_common_statements,
      local.sts_dev_management_statements
    )
  }
}

# ===================================
# デバッグ用出力
# ===================================

output "sts_policy_statement_counts" {
  description = "各環境のSTSポリシーのステートメント数"
  value = {
    for env, statements in local.policy_statements_sts :
    env => length(statements)
  }
}

output "sts_policy_summary" {
  description = "各環境のSTSポリシー概要"
  value = {
    local   = "Local環境用 - GetCallerIdentityとdevロールへのAssumeRole権限"
    dev     = "開発環境用 - GetCallerIdentityとdevロールへのAssumeRole権限"
    prod    = "本番環境用 - GetCallerIdentityとprodロールへのAssumeRole権限"
    default = "デフォルト（開発環境と同等）"
  }
}