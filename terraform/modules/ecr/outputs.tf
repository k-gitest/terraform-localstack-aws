# ECRリポジトリ情報
output "repository_name" {
  description = "ECRリポジトリの名前"
  value       = aws_ecr_repository.this.name
}

output "repository_url" {
  description = "ECRリポジトリのURL"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ECRリポジトリのARN（Amazon Resource Name）"
  value       = aws_ecr_repository.this.arn
}

output "registry_id" {
  description = "リポジトリが作成されたレジストリID"
  value       = aws_ecr_repository.this.registry_id
}

# Dockerコマンド用
output "repository_uri_with_tag" {
  description = "latestタグ付きのリポジトリURI（Dockerコマンドで使用）"
  value       = "${aws_ecr_repository.this.repository_url}:latest"
}

output "docker_login_command" {
  description = "DockerをECRで認証するためのAWS CLIコマンド"
  value       = "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${aws_ecr_repository.this.repository_url}"
}

# ポリシー情報
output "lifecycle_policy_created" {
  description = "ライフサイクルポリシーが作成されたかどうか"
  value       = var.enable_lifecycle_policy
}

output "repository_policy_created" {
  description = "リポジトリポリシーが作成されたかどうか"
  value       = var.enable_cross_account_access && length(var.allowed_account_ids) > 0
}

# 現在のリージョン取得用データソース
data "aws_region" "current" {}