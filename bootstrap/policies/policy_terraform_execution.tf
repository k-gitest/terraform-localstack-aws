# ===================================
# Terraform実行用ポリシー（統合）
# ===================================

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
      local.policy_statements_acm,

      # STS
      local.policy_statements_sts
    )
  })

  tags = {
    Name        = "${var.project_name}-TerraformExecution-${each.value}"
    Environment = each.value
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}