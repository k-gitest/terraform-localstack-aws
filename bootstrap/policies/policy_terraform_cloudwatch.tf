# ===================================
# CloudWatch Logs関連
# ===================================

locals {
  policy_statements_cloudwatch = [
    # 1. 読み取り専用操作
    {
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
        
        # メトリクスフィルタ
        "logs:DescribeMetricFilters",
        
        # サブスクリプションフィルタ
        "logs:DescribeSubscriptionFilters",
        
        # リソースポリシー
        "logs:DescribeResourcePolicies",
        
        # エクスポートタスク
        "logs:DescribeExportTasks"
      ]
      Resource = "*"  # 読み取りなので全体を許可
    },

    # 2. ロググループ管理
    {
      Effect = "Allow"
      Action = [
        # ロググループ作成・削除
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup",  # prod_restrictionsでDenyされる
        
        # 保持期間設定
        "logs:PutRetentionPolicy",
        "logs:DeleteRetentionPolicy",
        
        # タグ管理
        "logs:TagLogGroup",
        "logs:UntagLogGroup"
      ]
      Resource = [
        # ロググループの操作には:*が必要な場合と不要な場合がある
        # 安全のため両方を含める
        # Lambda用
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*",
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*:*",
        
        # ECS用
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-*",
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-*:*",
        
        # カスタムログ用
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/${var.project_name}/*",
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/${var.project_name}/*:*"
      ]
    },

    # 3. ログストリーム管理
    {
      Effect = "Allow"
      Action = [
        # ログストリーム作成・削除
        "logs:CreateLogStream",
        "logs:DeleteLogStream",
        
        # ログイベント書き込み
        "logs:PutLogEvents"
      ]
      Resource = [
        # Lambda用
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*:log-stream:*",
        
        # ECS用
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-*:log-stream:*",
        
        # カスタムログ用
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/${var.project_name}/*:log-stream:*"
      ]
    },

    # 4. メトリクスフィルタ管理
    {
      Effect = "Allow"
      Action = [
        "logs:PutMetricFilter",
        "logs:DeleteMetricFilter"
      ]
      Resource = [
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*",
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-*",
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/${var.project_name}/*"
      ]
    },

    # 5. サブスクリプションフィルタ管理
    {
      Effect = "Allow"
      Action = [
        "logs:PutSubscriptionFilter",
        "logs:DeleteSubscriptionFilter"
      ]
      Resource = [
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*",
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-*",
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/${var.project_name}/*"
      ]
    },

    # 6. リソースポリシー管理
    {
      Effect = "Allow"
      Action = [
        "logs:PutResourcePolicy",
        "logs:DeleteResourcePolicy"
      ]
      Resource = "*"  # リソースポリシーはグローバル
    }
  ]
}