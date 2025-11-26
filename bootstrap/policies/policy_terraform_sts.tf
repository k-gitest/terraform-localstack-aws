# ===================================
# STS (Security Token Service) 関連
# ===================================

locals {
  policy_statements_sts = [
    # アカウント情報取得
    # 用途: data "aws_caller_identity" でアカウントIDを取得
    #       ARN作成時に ${data.aws_caller_identity.current.account_id} として使用
    {
      Effect = "Allow"
      Action = [
        "sts:GetCallerIdentity"
      ]
      Resource = "*"  # STSの仕様上 "*" 必須
    }
  ]
}