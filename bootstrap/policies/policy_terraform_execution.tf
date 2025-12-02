# ===================================
# Terraform実行用ポリシー（統合）
# ===================================

# ===================================
# 環境別のポリシーステートメント生成
# ===================================
locals {
  # 各環境ごとに適切なポリシーステートメントを生成
  terraform_execution_policies = {
    for env in var.environments : env => concat(
      # EC2/VPC - 環境別のステートメントを使用
      try(local.policy_statements_ec2[env], local.policy_statements_ec2["default"]),
      
      # S3 - 環境別のステートメントを使用
      try(local.policy_statements_s3[env], local.policy_statements_s3["default"]),
      
      # IAM - 環境別のステートメントを使用
      try(local.policy_statements_iam[env], local.policy_statements_iam["default"]),
      
      # Lambda - 環境別のステートメントを使用
      try(local.policy_statements_lambda[env], local.policy_statements_lambda["default"]),
      
      # ECS/ECR - 環境別のステートメントを使用
      try(local.policy_statements_ecs_ecr[env], local.policy_statements_ecs_ecr["default"]),
      
      # RDS - 環境別のステートメントを使用
      try(local.policy_statements_rds[env], local.policy_statements_rds["default"]),
      
      # ALB - 環境別のステートメントを使用
      try(local.policy_statements_alb[env], local.policy_statements_alb["default"]),
      
      # CloudFront - 環境別のステートメントを使用
      try(local.policy_statements_cloudfront[env], local.policy_statements_cloudfront["default"]),
      
      # Amplify - 環境別のステートメントを使用
      try(local.policy_statements_amplify[env], local.policy_statements_amplify["default"]),
      
      # CloudWatch - 環境別のステートメントを使用
      try(local.policy_statements_cloudwatch[env], local.policy_statements_cloudwatch["default"]),
      
      # SSM - 環境別のステートメントを使用
      try(local.policy_statements_ssm[env], local.policy_statements_ssm["default"]),
      
      # Route53 - 環境別のステートメントを使用
      try(local.policy_statements_route53[env], local.policy_statements_route53["default"]),
      
      # ACM - 環境別のステートメントを使用
      try(local.policy_statements_acm[env], local.policy_statements_acm["default"]),
      
      # STS - すべての環境で共通
      local.policy_statements_sts
    )
  }
}

# ===================================
# Terraform実行用ポリシーリソース
# ===================================
resource "aws_iam_policy" "terraform_execution" {
  for_each = toset(var.environments)
  
  name        = "${var.project_name}-TerraformExecution-${each.value}"
  description = "Terraform実行用ポリシー for ${each.value} environment"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = local.terraform_execution_policies[each.value]
  })

  tags = {
    Name        = "${var.project_name}-TerraformExecution-${each.value}"
    Environment = each.value
    Project     = var.project_name
    ManagedBy   = "terraform"
    Purpose     = "Terraform automation via GitHub Actions"
  }
}

# ===================================
# ポリシーサイズのバリデーション
# ===================================
resource "null_resource" "policy_size_validation" {
  for_each = toset(var.environments)
  
  triggers = {
    policy_length = length(jsonencode({
      Version = "2012-10-17"
      Statement = local.terraform_execution_policies[each.value]
    }))
  }

  # IAMポリシーの最大サイズは6144文字
  # 警告を出すが、エラーにはしない
  provisioner "local-exec" {
    command = <<-EOT
      if [ ${self.triggers.policy_length} -gt 5000 ]; then
        echo "⚠️  警告: ${each.value} 環境のポリシーサイズが大きくなっています (${self.triggers.policy_length} 文字)"
        echo "📋 推奨: ポリシーを複数に分割することを検討してください"
      fi
    EOT
  }
}

# ===================================
# 出力: デバッグ用
# ===================================
output "terraform_execution_policy_arns" {
  description = "Terraform実行用ポリシーのARN"
  value = {
    for env in var.environments :
    env => aws_iam_policy.terraform_execution[env].arn
  }
}

output "terraform_execution_policy_sizes" {
  description = "各環境のポリシーサイズ（文字数）"
  value = {
    for env in var.environments :
    env => length(jsonencode({
      Version = "2012-10-17"
      Statement = local.terraform_execution_policies[env]
    }))
  }
}