# ===================================
# CloudWatch Logs関連ポリシー定義（環境分離・セキュリティ強化版）
# ===================================

locals {
  # ===================================
  # ロググループARNのベースパス定義
  # ===================================
  log_group_arn_bases = [
    "/aws/lambda", # Lambda用
    "/ecs",        # ECS用
    ""             # カスタムログ用 (例: /<project>-<env>/*)
  ]
  
  # 環境ごとに ARN リストを生成する関数 (ロググループ管理用)
  log_group_management_resources = {
    for env in ["dev", "prod"]:
    env => flatten([
      for base in local.log_group_arn_bases : [
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:${base}/${var.project_name}-${env}-*",
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:${base}/${var.project_name}-${env}-*:*"
      ]
    ])
  }

  # 環境ごとに ARN リストを生成する関数 (ログストリーム管理用)
  log_stream_management_resources = {
    for env in ["dev", "prod"]:
    env => flatten([
      for base in local.log_group_arn_bases : 
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:${base}/${var.project_name}-${env}-*:log-stream:*"
    ])
  }

  # ===================================
  # 共通ステートメント（読み取り専用）
  # ===================================
  cloudwatch_common_statements = [
    {
      Sid    = "CloudWatchLogsReadAccess"
      Effect = "Allow"
      Action = [
        # ロググループ
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:ListTagsLogGroup",
        # ログイベント
        "logs:GetLogEvents",
        "logs:FilterLogEvents",
        # クエリ
        "logs:DescribeQueries",
        "logs:GetQueryResults",
        "logs:StartQuery",
        "logs:StopQuery",
        # メトリクスフィルタ/サブスクリプションフィルタ
        "logs:DescribeMetricFilters",
        "logs:DescribeSubscriptionFilters",
        # リソースポリシー/エクスポート
        "logs:DescribeResourcePolicies",
        "logs:DescribeExportTasks"
      ]
      Resource = "*" # 読み取りなので全体を許可
    }
  ]
  
  # ===================================
  # 開発環境専用ステートメント（dev-* リソースへのフル管理）
  # ===================================
  cloudwatch_dev_management_statements = [
    # ロググループ管理（削除含む）
    {
      Sid    = "LogGroupManagementDev"
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup", # 開発環境は削除可能
        "logs:PutRetentionPolicy",
        "logs:DeleteRetentionPolicy",
        "logs:TagLogGroup",
        "logs:UntagLogGroup"
      ]
      Resource = local.log_group_management_resources["dev"]
    },

    # ログストリーム/イベント書き込み管理（削除含む）
    {
      Sid    = "LogStreamWriteManagementDev"
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:DeleteLogStream", # 削除可能
        "logs:PutLogEvents"
      ]
      Resource = local.log_stream_management_resources["dev"]
    },

    # フィルタ/サブスクリプション管理
    {
      Sid    = "FilterSubscriptionManagementDev"
      Effect = "Allow"
      Action = [
        "logs:PutMetricFilter",
        "logs:DeleteMetricFilter",
        "logs:PutSubscriptionFilter",
        "logs:DeleteSubscriptionFilter"
      ]
      # フィルタはロググループ ARN を Resource に取る
      Resource = [
        for arn in local.log_group_management_resources["dev"] : 
        replace(arn, ":*", "")
      ]
    },

    # リソースポリシー管理
    {
      Sid    = "ResourcePolicyManagementDev"
      Effect = "Allow"
      Action = [
        "logs:PutResourcePolicy",
        "logs:DeleteResourcePolicy"
      ]
      Resource = "*" # リソースポリシーはグローバル操作
    }
  ]
  
  # ===================================
  # 本番環境専用ステートメント（prod-* リソースへの作成・変更のみ）
  # ===================================
  cloudwatch_prod_management_statements = [
    # ロググループ管理（削除除外）
    {
      Sid    = "LogGroupManagementProd"
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        # "logs:DeleteLogGroup", # ❌ 除外
        "logs:PutRetentionPolicy",
        "logs:DeleteRetentionPolicy",
        "logs:TagLogGroup",
        "logs:UntagLogGroup"
      ]
      Resource = local.log_group_management_resources["prod"]
    },

    # ログストリーム/イベント書き込み管理
    {
      Sid    = "LogStreamWriteManagementProd"
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:DeleteLogStream", # ログローテーションのため許容
        "logs:PutLogEvents"
      ]
      Resource = local.log_stream_management_resources["prod"]
    },

    # フィルタ/サブスクリプション管理
    {
      Sid    = "FilterSubscriptionManagementProd"
      Effect = "Allow"
      Action = [
        "logs:PutMetricFilter",
        "logs:DeleteMetricFilter",
        "logs:PutSubscriptionFilter",
        "logs:DeleteSubscriptionFilter"
      ]
      # フィルタはロググループ ARN を Resource に取る
      Resource = [
        for arn in local.log_group_management_resources["prod"] : 
        replace(arn, ":*", "")
      ]
    },

    # リソースポリシー管理
    {
      Sid    = "ResourcePolicyManagementProd"
      Effect = "Allow"
      Action = [
        "logs:PutResourcePolicy",
        "logs:DeleteResourcePolicy"
      ]
      Resource = "*" # リソースポリシーはグローバル操作
    }
  ]
  
  # ===================================
  # Local環境専用ステートメント
  # ===================================
  cloudwatch_local_management_statements = local.cloudwatch_dev_management_statements

  # ===================================
  # 環境別ポリシーステートメントのマッピング
  # ===================================
  policy_statements_cloudwatch = {
    local = concat(
      local.cloudwatch_common_statements,
      local.cloudwatch_local_management_statements
    ),
    dev = concat(
      local.cloudwatch_common_statements,
      local.cloudwatch_dev_management_statements
    ),
    prod = concat(
      local.cloudwatch_common_statements,
      local.cloudwatch_prod_management_statements
    ),
    # デフォルト（フォールバック）
    default = concat(
      local.cloudwatch_common_statements,
      local.cloudwatch_dev_management_statements
    )
  }
}

# ===================================
# デバッグ用出力
# ===================================

output "cloudwatch_policy_statement_counts" {
  description = "各環境のCloudWatchポリシーのステートメント数"
  value = {
    for env, statements in local.policy_statements_cloudwatch :
    env => length(statements)
  }
}

output "cloudwatch_policy_summary" {
  description = "各環境のCloudWatchポリシー概要"
  value = {
    local   = "Local環境用 - ${var.project_name}-dev-*ロググループへのフル管理権限"
    dev     = "開発環境用 - ${var.project_name}-dev-*ロググループへのフル管理権限（ロググループ削除可）"
    prod    = "本番環境用 - ${var.project_name}-prod-*ロググループへの作成・更新権限のみ（ロググループ削除不可）"
    default = "デフォルト（開発環境と同等）"
  }
}