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
      local.policy_statements_cloudwatch
    )

    Statement = [
      # ===================================
      # Systems Manager Parameter Store関連
      # ===================================

      # プロジェクト固有のパラメータ（機密情報含む）
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",           # 単一パラメータ取得
          "ssm:GetParameters",          # 複数パラメータ取得（バッチ）
          "ssm:GetParametersByPath"     # パス配下の全パラメータ取得
        ]
        Resource = [
          # プロジェクト名で始まるパラメータのみアクセス可能
          # 例: /my-project/dev/db-password
          #     /my-project/prod/jwt-secret
          "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/*"
        ]
      },

      # ===================================
      # Route53関連
      # ===================================

      # 1. 読み取り専用操作
      {
        Effect = "Allow"
        Action = [
          # ホストゾーン
          "route53:GetHostedZone",
          "route53:ListHostedZones",
          "route53:ListHostedZonesByName",
          "route53:GetHostedZoneCount",
          
          # レコードセット
          "route53:ListResourceRecordSets",
          "route53:GetChange",
          
          # ヘルスチェック
          "route53:GetHealthCheck",
          "route53:GetHealthCheckCount",
          "route53:GetHealthCheckStatus",
          "route53:ListHealthChecks",
          
          # トラフィックポリシー
          "route53:GetTrafficPolicy",
          "route53:ListTrafficPolicies",
          "route53:GetTrafficPolicyInstance",
          "route53:ListTrafficPolicyInstances",
          
          # タグ
          "route53:ListTagsForResource",
          "route53:ListTagsForResources"
        ]
        Resource = "*"
      },

      # 2. ホストゾーン作成（タグ必須）
      {
        Effect = "Allow"
        Action = [
          "route53:CreateHostedZone"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/Project": var.project_name
            "aws:RequestTag/ManagedBy": "terraform"
          }
        }
      },

      # 3. ホストゾーン更新・削除（タグフィルタ）
      {
        Effect = "Allow"
        Action = [
          "route53:UpdateHostedZoneComment",
          "route53:DeleteHostedZone",  # prod_restrictionsでDenyされる
          "route53:ChangeTagsForResource"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Project": var.project_name
          }
        }
      },

      # 4. レコードセット管理（安全なレコードタイプのみ）
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Project": var.project_name
          }
          StringLike = {
            "route53:ChangeResourceRecordSetsRecordType": [
              "A",
              "AAAA",
              "CNAME",
              "TXT",    # ACM証明書検証用
              "MX",     # メール用
              "SRV"     # サービスディスカバリ用
            ]
          }
        }
      },

      # 5. NS/SOAレコードの変更を拒否
      {
        Effect = "Deny"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "route53:ChangeResourceRecordSetsRecordType": [
              "NS",   # ネームサーバー
              "SOA"   # Start of Authority
            ]
          }
        }
      },

      # 6. ヘルスチェック作成（タグ必須）
      # {
      #  Effect = "Allow"
      #   Action = [
      #     "route53:CreateHealthCheck"
      #   ]
      #   Resource = "*"
      #   Condition = {
      #     StringEquals = {
      #       "aws:RequestTag/Project": var.project_name
      #       "aws:RequestTag/ManagedBy": "terraform"
      #     }
      #   }
      # },

      # 7. ヘルスチェック更新・削除（タグフィルタ）
      # {
      #   Effect = "Allow"
      #   Action = [
      #     "route53:UpdateHealthCheck",
      #     "route53:DeleteHealthCheck",  # prod_restrictionsでDenyされる
      #     "route53:ChangeTagsForResource"
      #   ]
      #   Resource = "*"
      #   Condition = {
      #     StringEquals = {
      #       "aws:ResourceTag/Project": var.project_name
      #     }
      #   }
      # },

      # 8. トラフィックポリシー管理
      # {
      #   Effect = "Allow"
      #   Action = [
      #     # トラフィックポリシー作成・更新・削除
      #     "route53:CreateTrafficPolicy",
      #     "route53:UpdateTrafficPolicy",
      #     "route53:DeleteTrafficPolicy",  # prod_restrictionsでDenyされる
      #     
          # トラフィックポリシーインスタンス
      #     "route53:CreateTrafficPolicyInstance",
      #     "route53:UpdateTrafficPolicyInstance",
      #     "route53:DeleteTrafficPolicyInstance"  # prod_restrictionsでDenyされる
      #   ]
      #   Resource = [
      #     "arn:aws:route53:::trafficpolicy/*"
      #   ]
      # },

      # ===================================
      # AWS Certificate Manager (ACM) 関連
      # ===================================

      # 1. 読み取り専用操作
      {
        Effect = "Allow"
        Action = [
          "acm:DescribeCertificate",
          "acm:GetCertificate",
          "acm:ListCertificates",
          "acm:ListTagsForCertificate"
        ]
        Resource = "*"
      },

      # 2. 証明書リクエスト
      {
        Effect = "Allow"
        Action = [
          "acm:RequestCertificate"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/Project": var.project_name
            "aws:RequestTag/ManagedBy": "terraform"
          }
        }
      },

      # 3. 証明書管理
      {
        Effect = "Allow"
        Action = [
          "acm:DeleteCertificate",  # prod_restrictionsでDenyされる
          "acm:RenewCertificate",
          "acm:ResendValidationEmail",
          "acm:AddTagsToCertificate",
          "acm:RemoveTagsFromCertificate"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Project": var.project_name
          }
        }
      },

      # 4. 証明書インポート（必要な場合のみ）
      {
        Effect = "Allow"
        Action = [
          "acm:ImportCertificate"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/Project": var.project_name
            "aws:RequestTag/ManagedBy": "terraform"
          }
        }
      },

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