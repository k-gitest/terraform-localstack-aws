# ===================================
# Terraform実行用ポリシー（統合）
# ===================================
# !!! 🚨 セキュリティリスク警告 🚨 !!!
# 【本ポリシーはインフラ構築時の暫定的なフルアクセス権限を含みます】
# このポリシーのまま実装すると、多くのActionに"*"、Resourceに"*"が含まれており、攻撃者に悪用された場合、
# 環境全体（DB、ECS、VPCなど）の**破壊やデータ窃取を許します**。
# 🚀 【実装時の最優先事項】
# 1. Actionを厳密に必要なAPIコールに限定すること。
# 2. Resourceを**特定のARN**に限定すること (例: ${var.project_name}-* で始まるリソースのみ)。
# 3. 特にRDSのDelete/Terminate, ECSのDelete Clusterなどの**破壊的な操作はDenyを検討**すること。

resource "aws_iam_policy" "terraform_execution" {
  for_each = toset(var.environments)
  
  name        = "${var.project_name}-TerraformExecution-${each.value}"
  description = "Terraform実行用ポリシー for ${each.value} environment"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # EC2/VPC
      local.policy_statements_ec2,
      
      # S3
      local.policy_statements_s3,

      # IAM
      local.policy_statements_iam,

      # Lambda
      local.policy_statements_lambda,

      # ECS/ECR
      local.policy_statements_ecs_ecr,

      # RDS
      local.policy_statements_rds,

      # ALB
      local.policy_statements_alb,

      # CloudFront
      local.policy_statements_cloudfront,

      # Amplify
      local.policy_statements_amplify,

      # CloudWatch
      local.policy_statements_cloudwatch,

      # SSM
      local.policy_statements_ssm,

      # Route53
      local.policy_statements_route53,

      # ACM
      local.policy_statements_acm
    )

    Statement = [
      # ===================================
      # STS (Security Token Service) 関連
      # ===================================

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
  })

  tags = {
    Name        = "${var.project_name}-TerraformExecution-${each.value}"
    Environment = each.value
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}