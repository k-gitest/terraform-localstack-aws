# ===================================
# バックエンドci/cdデプロイ用ポリシー
# ===================================
resource "aws_iam_policy" "backend_deploy" {
  for_each = toset(var.environments)
  
  name        = "${var.project_name}-BackendDeploy-${each.value}"
  description = "バックエンドデプロイ用ポリシー for ${each.value} environment"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ECR認証
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      # ECRイメージプッシュ権限
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:DescribeImages",
          "ecr:ListImages"
        ]
        Resource = [
          "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-${each.value}-*"
        ]
      },
      # ECSサービス更新通知用（オプション）
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-BackendDeploy-${each.value}"
    Environment = each.value
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}
