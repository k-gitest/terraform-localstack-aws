# ===================================
# Lambda関連ポリシー定義
# ===================================

locals {
  policy_statements_lambda = [
    # 1. 読み取り専用操作
    {
      Effect = "Allow"
      Action = [
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
      Resource = "*"  # 読み取りなので全体を許可
    },

    # 2. 関数の作成・更新・削除
    {
      Effect = "Allow"
      Action = [
        # 関数管理
        "lambda:CreateFunction",
        "lambda:DeleteFunction",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:PublishVersion",
        
        # エイリアス管理
        "lambda:CreateAlias",
        "lambda:UpdateAlias",
        "lambda:DeleteAlias",
        
        # タグ管理
        "lambda:TagResource",
        "lambda:UntagResource"
      ]
      Resource = [
        "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*"
      ]
    },

    # 3. Lambda実行権限の設定
    {
      Effect = "Allow"
      Action = [
        "lambda:AddPermission",
        "lambda:RemovePermission"
      ]
      Resource = [
        "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*"
      ]
    },

    # 4. 環境変数・VPC設定
    {
      Effect = "Allow"
      Action = [
        "lambda:UpdateFunctionConfiguration"
      ]
      Resource = [
        "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*"
      ]
    },

    # 5. イベントソースマッピング（S3, SQS等とのトリガー連携）
    {
      Effect = "Allow"
      Action = [
        "lambda:CreateEventSourceMapping",
        "lambda:UpdateEventSourceMapping",
        "lambda:DeleteEventSourceMapping"
      ]
      Resource = "*"  # イベントソースマッピングはARNパターンが複雑
    },

    # 6. Lambda Layer管理
    {
      Effect = "Allow"
      Action = [
        "lambda:PublishLayerVersion",
        "lambda:DeleteLayerVersion",
        "lambda:AddLayerVersionPermission",
        "lambda:RemoveLayerVersionPermission"
      ]
      Resource = [
        "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:layer:${var.project_name}-*"
      ]
    },

    # 7. 同時実行数の設定
    {
      Effect = "Allow"
      Action = [
        "lambda:PutFunctionConcurrency",
        "lambda:DeleteFunctionConcurrency"
      ]
      Resource = [
        "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*"
      ]
    },

    # 8. CloudWatch Logs権限（Lambdaログ用）
    {
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
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*",
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*:*"
      ]
    }
  ]
}