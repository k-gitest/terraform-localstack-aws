# ===================================
# Systems Manager Parameter Store関連
# ===================================

locals {
  policy_statements_ssm = [
    # プロジェクト固有のパラメータ（機密情報含む）
    {
      Effect = "Allow"
      Action = [
        "ssm:GetParameter",           # 単一パラメータ取得
        "ssm:GetParameters",          # 複数パラメータ取得（バッチ）
        "ssm:GetParametersByPath"     # パス配下の全パラメータ取得
      ]
      Resource = [
        # プロジェクト名で始まるパラメータのみアクセス可能
        # 例: /my-project/dev/db-password
        #     /my-project/prod/jwt-secret
        "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/*"
      ]
    }
  ]
}