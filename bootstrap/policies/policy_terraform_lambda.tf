# ===================================
# Lambda関連ポリシー定義（環境分離・セキュリティ強化版）
# ===================================

locals {
  # ===================================
  # 共通ステートメント（読み取り専用）
  # ===================================
  lambda_common_statements = [
    {
      Sid      = "LambdaReadAccess"
      Effect   = "Allow"
      Action   = [
        "lambda:GetFunction",
        "lambda:GetFunctionConfiguration",
        "lambda:GetFunctionCodeSigningConfig",
        "lambda:GetFunctionConcurrency",
        "lambda:GetFunctionEventInvokeConfig",
        "lambda:GetPolicy",
        "lambda:GetLayerVersion",
        "lambda:GetLayerVersionPolicy",
        "lambda:ListFunctions",
        "lambda:ListVersionsByFunction",
        "lambda:ListAliases",
        "lambda:ListLayers",
        "lambda:ListLayerVersions",
        "lambda:ListTags",
        "lambda:ListEventSourceMappings"
      ]
      Resource = "*" 
    }
  ]
  
  # ===================================
  # 開発環境専用ステートメント（dev-* リソースへのフル管理）
  # ===================================
  lambda_dev_management_statements = [
    # 関数管理（作成・更新・削除）
    {
      Sid    = "FunctionManagementDev"
      Effect = "Allow"
      Action = [
        # 関数管理（削除含む）
        "lambda:CreateFunction",
        "lambda:DeleteFunction",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:PublishVersion",
        # エイリアス管理
        "lambda:CreateAlias",
        "lambda:UpdateAlias",
        "lambda:DeleteAlias",
        # 環境変数・VPC設定（UpdateFunctionConfigurationに含まれるが明示的に再定義しても可）
        # タグ管理
        "lambda:TagResource",
        "lambda:UntagResource"
      ]
      Resource = "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-dev-*"
    },
    
    # Lambda実行権限の設定
    {
      Sid      = "FunctionPermissionDev"
      Effect   = "Allow"
      Action   = [
        "lambda:AddPermission",
        "lambda:RemovePermission"
      ]
      Resource = "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-dev-*"
    },
    
    # イベントソースマッピング（環境分離が困難なためResource="*"を許容）
    {
      Sid    = "EventSourceMappingDev"
      Effect = "Allow"
      Action = [
        "lambda:CreateEventSourceMapping",
        "lambda:UpdateEventSourceMapping",
        "lambda:DeleteEventSourceMapping"
      ]
      Resource = "*" 
    },
    
    # Lambda Layer管理（作成・削除含む）
    {
      Sid    = "LayerManagementDev"
      Effect = "Allow"
      Action = [
        "lambda:PublishLayerVersion",
        "lambda:DeleteLayerVersion",
        "lambda:AddLayerVersionPermission",
        "lambda:RemoveLayerVersionPermission"
      ]
      Resource = "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:layer:${var.project_name}-dev-*"
    },
    
    # 同時実行数の設定
    {
      Sid    = "ConcurrencyManagementDev"
      Effect = "Allow"
      Action = [
        "lambda:PutFunctionConcurrency",
        "lambda:DeleteFunctionConcurrency"
      ]
      Resource = "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-dev-*"
    },
    
    # CloudWatch Logs権限（ロググループ削除含む）
    {
      Sid    = "LogsManagementDev"
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:DeleteLogGroup"
      ]
      Resource = [
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-dev-*",
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-dev-*:*"
      ]
    }
  ]
  
  # ===================================
  # 本番環境専用ステートメント（prod-* リソースへの作成・変更のみ）
  # ===================================
  lambda_prod_management_statements = [
    # 関数管理（作成・更新のみ - 削除系アクションを意図的に除外）
    {
      Sid    = "FunctionManagementProd"
      Effect = "Allow"
      Action = [
        # 関数管理
        "lambda:CreateFunction",
        # "lambda:DeleteFunction" は除外
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:PublishVersion",
        # エイリアス管理
        "lambda:CreateAlias",
        "lambda:UpdateAlias",
        # "lambda:DeleteAlias" は除外
        # タグ管理
        "lambda:TagResource",
        "lambda:UntagResource"
      ]
      Resource = "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-prod-*"
    },
    
    # Lambda実行権限の設定
    {
      Sid      = "FunctionPermissionProd"
      Effect   = "Allow"
      Action   = [
        "lambda:AddPermission",
        "lambda:RemovePermission"
      ]
      Resource = "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-prod-*"
    },
    
    # イベントソースマッピング（prod環境もResource="*"を許容）
    {
      Sid    = "EventSourceMappingProd"
      Effect = "Allow"
      Action = [
        "lambda:CreateEventSourceMapping",
        "lambda:UpdateEventSourceMapping",
        "lambda:DeleteEventSourceMapping"
      ]
      Resource = "*" 
    },
    
    # Lambda Layer管理（作成のみ - 削除系アクションを意図的に除外）
    {
      Sid    = "LayerManagementProd"
      Effect = "Allow"
      Action = [
        "lambda:PublishLayerVersion",
        # "lambda:DeleteLayerVersion" は除外
        "lambda:AddLayerVersionPermission",
        "lambda:RemoveLayerVersionPermission"
      ]
      Resource = "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:layer:${var.project_name}-prod-*"
    },
    
    # 同時実行数の設定
    {
      Sid    = "ConcurrencyManagementProd"
      Effect = "Allow"
      Action = [
        "lambda:PutFunctionConcurrency",
        "lambda:DeleteFunctionConcurrency"
      ]
      Resource = "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-prod-*"
    },
    
    # CloudWatch Logs権限（ロググループ削除を除外）
    {
      Sid    = "LogsManagementProd"
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
        # "logs:DeleteLogGroup" は除外
      ]
      Resource = [
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-prod-*",
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-prod-*:*"
      ]
    }
  ]
  
  # ===================================
  # Local環境専用ステートメント
  # ===================================
  lambda_local_management_statements = local.lambda_dev_management_statements

  # ===================================
  # 環境別ポリシーステートメントのマッピング
  # ===================================
  policy_statements_lambda = {
    local = concat(
      local.lambda_common_statements,
      local.lambda_local_management_statements
    ),
    dev = concat(
      local.lambda_common_statements,
      local.lambda_dev_management_statements
    ),
    prod = concat(
      local.lambda_common_statements,
      local.lambda_prod_management_statements
    ),
    # デフォルト（フォールバック）
    default = concat(
      local.lambda_common_statements,
      local.lambda_dev_management_statements
    )
  }
}

# ===================================
# デバッグ用出力
# ===================================

output "lambda_policy_statement_counts" {
  description = "各環境のLambdaポリシーステートメント数"
  value = {
    for env, statements in local.policy_statements_lambda :
    env => length(statements)
  }
}

output "lambda_policy_summary" {
  description = "各環境のLambdaポリシー概要"
  value = {
    local   = "Local環境用 - ${var.project_name}-dev-*と同等のフル管理権限"
    dev     = "開発環境用 - ${var.project_name}-dev-* リソースへのフル管理権限（削除可）"
    prod    = "本番環境用 - ${var.project_name}-prod-* リソースへの作成・変更権限のみ（削除不可）"
    default = "デフォルト（開発環境と同等）"
  }
}