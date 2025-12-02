# ===================================
# 本番環境への追加制限ポリシー（最終版）
# ===================================
resource "aws_iam_policy" "prod_restrictions" {
  count = contains(var.environments, "prod") ? 1 : 0
  
  name        = "${var.project_name}-ProdRestrictions"
  description = "本番環境での破壊的操作を明示的に拒否するポリシー"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ===================================
      # リソース保護（破壊的操作の拒否）
      # ===================================

      # EC2/VPCの破壊的操作を拒否
      {
        Sid    = "DenyEC2VPCDeletion"
        Effect = "Deny"
        Action = [
          "ec2:TerminateInstances",
          "ec2:DeleteVpc",
          "ec2:DeleteSubnet",
          "ec2:DeleteRouteTable",
          "ec2:DeleteRoute",
          "ec2:DeleteInternetGateway",
          "ec2:DeleteNatGateway",
          "ec2:ReleaseAddress",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteNetworkAcl",
          "ec2:DeleteNetworkAclEntry",
          "ec2:DeleteVpcEndpoints"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Environment" = "prod"
            "aws:ResourceTag/Project"     = var.project_name
          }
        }
      },

      # S3の破壊的操作を完全に拒否
      {
        Sid    = "DenyS3Deletion"
        Effect = "Deny"
        Action = [
          "s3:DeleteBucket",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:DeleteBucketPolicy"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-prod-*",
          "arn:aws:s3:::${var.project_name}-prod-*/*"
        ]
      },
      
      # IAMの破壊的操作を拒否
      {
        Sid    = "DenyIAMDeletion"
        Effect = "Deny"
        Action = [
          "iam:DeleteRole",
          "iam:DeletePolicy",
          "iam:DeleteRolePolicy",
          "iam:DeleteInstanceProfile",
          "iam:DetachRolePolicy"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-prod-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project_name}-prod-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.project_name}-prod-*"
        ]
      },
      
      # 管理者権限ポリシーのアタッチを拒否（権限エスカレーション防止）
      {
        Sid    = "DenyAdminPolicyAttachment"
        Effect = "Deny"
        Action = [
          "iam:AttachRolePolicy"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "iam:PolicyARN": [
              "arn:aws:iam::aws:policy/AdministratorAccess",
              "arn:aws:iam::aws:policy/PowerUserAccess",
              "arn:aws:iam::aws:policy/IAMFullAccess"
            ]
          }
        }
      },
      
      # Lambda関数の削除を拒否
      {
        Sid    = "DenyLambdaDeletion"
        Effect = "Deny"
        Action = [
          "lambda:DeleteFunction",
          "lambda:DeleteAlias",
          "lambda:DeleteLayerVersion",
          "lambda:DeleteEventSourceMapping"
        ]
        Resource = [
          "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-prod-*",
          "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:layer:${var.project_name}-prod-*"
        ]
      },

      # ECS/ECRの破壊的操作を拒否
      {
        Sid    = "DenyECSECRDeletion"
        Effect = "Deny"
        Action = [
          "ecs:DeleteCluster",
          "ecs:DeleteService",
          "ecr:DeleteRepository",
          "ecr:BatchDeleteImage"
        ]
        Resource = [
          "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:cluster/${var.project_name}-prod-*",
          "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:service/${var.project_name}-prod-*/*",
          "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-prod-*"
        ]
      },

      # RDSの破壊的操作を拒否
      {
        Sid    = "DenyRDSDeletion"
        Effect = "Deny"
        Action = [
          "rds:DeleteDBInstance",
          "rds:DeleteDBCluster",
          "rds:DeleteDBSnapshot",
          "rds:DeleteDBClusterSnapshot"
        ]
        Resource = [
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:db:${var.project_name}-prod-*",
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:cluster:${var.project_name}-prod-*",
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:snapshot:${var.project_name}-prod-*",
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:cluster-snapshot:${var.project_name}-prod-*"
        ]
      },

      # RDS暗号化の無効化を拒否
      {
        Sid    = "DenyRDSEncryptionDisable"
        Effect = "Deny"
        Action = [
          "rds:ModifyDBInstance",
          "rds:ModifyDBCluster"
        ]
        Resource = [
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:db:${var.project_name}-prod-*",
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:cluster:${var.project_name}-prod-*"
        ]
        Condition = {
          StringEquals = {
            "rds:StorageEncrypted": "false"
          }
        }
      },

      # ALB/ELBの破壊的操作を拒否
      {
        Sid    = "DenyALBDeletion"
        Effect = "Deny"
        Action = [
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteTargetGroup"
          # リスナー/ルール削除は設定変更のため許可（Allow側でコメント済み）
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:loadbalancer/app/${var.project_name}-prod-*",
          "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:loadbalancer/net/${var.project_name}-prod-*",
          "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:targetgroup/${var.project_name}-prod-*"
        ]
      },

      # CloudFrontの破壊的操作を拒否
      {
        Sid    = "DenyCloudFrontDeletion"
        Effect = "Deny"
        Action = [
          "cloudfront:DeleteDistribution",
          "cloudfront:DeleteCachePolicy",
          "cloudfront:DeleteOriginRequestPolicy",
          "cloudfront:DeleteResponseHeadersPolicy",
          "cloudfront:DeleteOriginAccessControl",
          "cloudfront:DeleteFunction"
        ]
        Resource = [
          "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/*",
          "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:cache-policy/*",
          "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:origin-request-policy/*",
          "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:response-headers-policy/*",
          "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:origin-access-control/*",
          "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:function/*"
        ]
      },

      # Amplifyの破壊的操作を拒否
      {
        Sid    = "DenyAmplifyDeletion"
        Effect = "Deny"
        Action = [
          "amplify:DeleteApp",
          "amplify:DeleteBranch",
          "amplify:DeleteBackendEnvironment",
          "amplify:DeleteWebhook"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Environment" = "prod"
            "aws:ResourceTag/Project"     = var.project_name
          }
        }
      },

      # CloudWatch Logsの破壊的操作を拒否
      {
        Sid    = "DenyCloudWatchLogsDeletion"
        Effect = "Deny"
        Action = [
          "logs:DeleteLogGroup",
          "logs:DeleteRetentionPolicy"
          # ログストリーム削除はローテーションのため許可
        ]
        Resource = [
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-prod-*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-prod-*:*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-prod-*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-prod-*:*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/${var.project_name}/prod/*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/${var.project_name}/prod/*:*"
        ]
      },

      # SSMパラメータの破壊的操作を拒否
      {
        Sid    = "DenySSMDeletion"
        Effect = "Deny"
        Action = [
          "ssm:DeleteParameter",
          "ssm:DeleteParameters"
        ]
        Resource = [
          "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/prod/*"
        ]
      },

      # Route53の破壊的操作を拒否
      {
        Sid    = "DenyRoute53Deletion"
        Effect = "Deny"
        Action = [
          "route53:DeleteHostedZone",
          "route53:DeleteHealthCheck",
          "route53:DeleteTrafficPolicy",
          "route53:DeleteTrafficPolicyInstance"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Environment" = "prod"
            "aws:ResourceTag/Project"     = var.project_name
          }
        }
      },

      # ACM証明書の破壊的操作を拒否
      {
        Sid    = "DenyACMDeletion"
        Effect = "Deny"
        Action = [
          "acm:DeleteCertificate",
          "acm:ExportCertificate"  # 秘密鍵エクスポートも防止
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Environment" = "prod"
            "aws:ResourceTag/Project"     = var.project_name
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ProdRestrictions"
    Environment = "prod"
    Project     = var.project_name
    ManagedBy   = "terraform"
    Purpose     = "Deny destructive operations in production environment"
  }
}