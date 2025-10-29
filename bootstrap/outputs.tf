# ===================================
# OIDC プロバイダー情報
# ===================================
output "oidc_provider_arn" {
  description = "GitHub OIDC プロバイダーのARN"
  value       = aws_iam_openid_connect_provider.github.arn
}

# ===================================
# Terraform実行用ロール（IaCリポジトリ用）
# ===================================
output "github_actions_role_arns" {
  description = "GitHub Actions用IAMロールのARN"
  value = {
    for env in var.environments : env => aws_iam_role.github_actions[env].arn
  }
}

output "github_repository_variables" {
  description = "GitHub リポジトリに設定すべき変数"
  value = {
    for env in var.environments : env => {
      AWS_ROLE_TO_ASSUME = aws_iam_role.github_actions[env].arn
      AWS_REGION         = "ap-northeast-1"
    }
  }
}

# ===================================
# フロントエンドデプロイ用ロール
# ===================================
output "github_actions_frontend_role_arns" {
  description = "GitHub Actions用IAMロール（フロントエンドデプロイ用）のARN"
  value = {
    for env in var.environments : env => aws_iam_role.github_actions_frontend[env].arn
  }
}

# ===================================
# バックエンドデプロイ用ロール
# ===================================
output "github_actions_backend_role_arns" {
  description = "GitHub Actions用IAMロール（バックエンドデプロイ用）のARN"
  value = {
    for env in var.environments : env => aws_iam_role.github_actions_backend[env].arn
  }
}