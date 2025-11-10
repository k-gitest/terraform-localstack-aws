# ===================================
# フロントエンドci/cdデプロイ用ポリシー
# ===================================
# S3アプリデプロイ用のポリシー
# これはアプリケーションリポジトリからのCI/CDデプロイ用
# github actionsからawsを操作する場合のポリシー
resource "aws_iam_policy" "frontend_deploy" {
  for_each = toset(var.environments)
  
  name        = "${var.project_name}-FrontendDeploy-${each.value}"
  description = "アプリケーションデプロイ用ポリシー for ${each.value} environment"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3バケットへのデプロイ権限（ビルド成果物のアップロード）
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject", # 古いファイルの削除用
          "s3:ListBucket",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${each.value}-frontend*",
          "arn:aws:s3:::${var.project_name}-${each.value}-frontend*/*"
        ]
      },
      # CloudFrontキャッシュクリア権限
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations"
        ]
        Resource = "*"
      },
      # CloudFront distribution情報取得権限
      {
        Effect = "Allow"
        Action = [
          "cloudfront:GetDistribution",
          "cloudfront:ListDistributions"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-FrontendDeploy-${each.value}"
    Environment = each.value
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}