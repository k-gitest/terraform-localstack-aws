# ===================================
# 本番環境には追加の制限を設ける場合のポリシー
# ===================================
resource "aws_iam_policy" "prod_restrictions" {
  count = contains(var.environments, "prod") ? 1 : 0
  
  name        = "${var.project_name}-ProdRestrictions"
  description = "本番環境での追加制限ポリシー"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ===================================
      # リソース保護（破壊的操作の拒否）
      # ===================================

      # EC2/RDSの破壊的操作を特定リージョン外で拒否
      {
        Effect = "Deny"
        Action = [
          "ec2:TerminateInstances",
          "rds:DeleteDBInstance",
          "rds:DeleteDBCluster"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion": ["ap-northeast-1"]
          }
        }
      },

      # S3の破壊的操作を完全に拒否
      {
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
      
      # 管理者権限ポリシーのアタッチを拒否
      {
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
        Effect = "Deny"
        Action = [
          # ECSクラスター削除
          "ecs:DeleteCluster",
          "ecs:DeleteService",
          
          # ECRリポジトリ削除
          "ecr:DeleteRepository",
          
          # ECRイメージ削除
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
        Effect = "Deny"
        Action = [
          # インスタンス削除
          "rds:DeleteDBInstance",
          "rds:DeleteDBCluster",
          
          # スナップショット削除
          "rds:DeleteDBSnapshot",
          "rds:DeleteDBClusterSnapshot",
          
          # 暗号化の無効化（既存のEC2/RDSのConditionと統合）
          "rds:ModifyDBInstance",
          "rds:ModifyDBCluster"
        ]
        Resource = [
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:db:${var.project_name}-prod-*",
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:cluster:${var.project_name}-prod-*",
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:snapshot:${var.project_name}-prod-*",
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:cluster-snapshot:${var.project_name}-prod-*"
        ]
        # ModifyのみConditionを追加（削除操作には不要）
        Condition = {
          StringEquals = {
            # 暗号化を無効化する変更を拒否
            "rds:StorageEncrypted": "false"
          }
        }
      },

      # ALB/ELBの破壊的操作を拒否
      {
        Effect = "Deny"
        Action = [
          # ロードバランサー削除
          "elasticloadbalancing:DeleteLoadBalancer",
          
          # ターゲットグループ削除
          "elasticloadbalancing:DeleteTargetGroup",
          
          # リスナー削除
          "elasticloadbalancing:DeleteListener",
          
          # ルール削除
          "elasticloadbalancing:DeleteRule"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:loadbalancer/app/${var.project_name}-prod-*",
          "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:loadbalancer/net/${var.project_name}-prod-*",
          "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:targetgroup/${var.project_name}-prod-*",
          "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener/app/${var.project_name}-prod-*",
          "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener/net/${var.project_name}-prod-*",
          "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener-rule/app/${var.project_name}-prod-*",
          "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener-rule/net/${var.project_name}-prod-*"
        ]
      },

      # CloudFrontの破壊的操作を拒否
      {
        Effect = "Deny"
        Action = [
          # ディストリビューション削除
          "cloudfront:DeleteDistribution",
          
          # ポリシー削除
          "cloudfront:DeleteCachePolicy",
          "cloudfront:DeleteOriginRequestPolicy",
          "cloudfront:DeleteResponseHeadersPolicy",
          
          # OAC削除
          "cloudfront:DeleteOriginAccessControl",
          
          # Functions削除
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
            "aws:ResourceTag/Environment": "prod"
            "aws:ResourceTag/Project": var.project_name
          }
        }
      },

      # CloudWatch Logsの破壊的操作を拒否
      {
        Effect = "Deny"
        Action = [
          # ロググループ削除
          "logs:DeleteLogGroup",
          
          # ログストリーム削除
          "logs:DeleteLogStream",
          
          # 保持期間の短縮（証跡削除の可能性）
          "logs:DeleteRetentionPolicy"
        ]
        Resource = [
          # Lambda用
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-prod-*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-prod-*:*",
          
          # ECS用
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-prod-*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-prod-*:*",
          
          # カスタムログ用
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/${var.project_name}/prod/*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/${var.project_name}/prod/*:*"
        ]
      },

      # Route53の破壊的操作を拒否
      {
        Effect = "Deny"
        Action = [
          # ホストゾーン削除
          "route53:DeleteHostedZone",
          
          # ヘルスチェック削除
          "route53:DeleteHealthCheck",
          
          # トラフィックポリシー削除
          "route53:DeleteTrafficPolicy",
          "route53:DeleteTrafficPolicyInstance"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Environment": "prod"
            "aws:ResourceTag/Project": var.project_name
          }
        }
      },

      # ACM証明書の破壊的操作を拒否
      {
        Effect = "Deny"
        Action = [
          # 証明書削除
          "acm:DeleteCertificate",
          
          # 秘密鍵エクスポート（超危険）
          "acm:ExportCertificate"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Environment": "prod"
            "aws:ResourceTag/Project": var.project_name
          }
        }
      },

      # ===================================
      # セキュリティ強化（権限エスカレーション防止）
      # ===================================

      # IAMの破壊的操作を拒否
      # 攻撃者がAdministratorAccess等をアタッチして全権限を取得するのを防ぐ
      {
        Effect = "Deny"
        Action = [
          "iam:DeleteRole",
          "iam:DeletePolicy",
          "iam:DeleteRolePolicy",
          "iam:DetachRolePolicy"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-prod-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project_name}-prod-*"
        ]
      }

    ]
  })

  tags = {
    Name        = "${var.project_name}-ProdRestrictions"
    Environment = "prod"
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}