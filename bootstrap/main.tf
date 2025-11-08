# ===================================
# GitHub Actions OIDCプロバイダーとロールのセットアップ
# ===================================
# このファイルは最初に手動で実行して、OIDC認証基盤を構築する

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Terraform Cloud を使用（OIDC基盤管理用）
  cloud {
    organization = "your-terraform-cloud-org"
    workspaces {
      name = "bootstrap-oidc"
    }
  }

  # S3バックエンドを使用する場合（Terraform Cloudを使わない場合のみ）
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "bootstrap/oidc/terraform.tfstate"
  #   region = "ap-northeast-1"
  # }
}

# ===================================
# 事前準備: AWSアカウント情報の取得
# ===================================
 
# このデータソースで取得する情報:
#   - account_id: AWSアカウントID (例: 123456789012)
#   - arn: 実行者のARN
#   - user_id: 実行者のユニークID
#
# 【重要】アカウントIDを明示的に指定する理由:
#   ワイルドカード (::*:) を使用すると、任意のAWSアカウントのリソースを
#   操作できてしまい、セキュリティリスクとなるため。
#
#   ❌ 危険: "arn:aws:iam::*:role/${var.project_name}-*"
#   ✅ 安全: "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"
#
# 使用箇所:
#   - terraform_execution ポリシーのIAM Resource指定
#   - prod_restrictions ポリシーのIAM Resource指定

# 現在のアカウントIDを取得
data "aws_caller_identity" "current" {}

# OIDCサーバー証明書のサムプリントをopenID Connectプロバイダーで使用するために取得
data "tls_certificate" "github_actions_deploy" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

# ===================================
# GitHub OIDC プロバイダー
# ===================================
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  # GitHubの証明書サムプリント
  thumbprint_list = [
    data.tls_certificate.github_actions_deploy.certificates[0].sha1_fingerprint
  ]

  tags = {
    Name      = "${var.project_name}-github-oidc-provider"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# ===================================
# terraform実行各環境用のIAMロール
# ===================================
resource "aws_iam_role" "github_actions" {
  for_each = toset(var.environments)
  
  name = "${var.project_name}-GitHubActions-${each.value}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_repository}:ref:refs/heads/main",
              "repo:${var.github_repository}:ref:refs/heads/develop",
              "repo:${var.github_repository}:pull_request"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-GitHubActions-${each.value}"
    Environment = each.value
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# ===================================
# フロントエンド用ロール
# ===================================
resource "aws_iam_role" "github_actions_frontend" {
  for_each = toset(var.environments)
  
  name = "${var.project_name}-GitHubActions-Frontend-${each.value}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_repository_frontend}:ref:refs/heads/main",
              "repo:${var.github_repository_frontend}:ref:refs/heads/develop"
            ]
          }
        }
      }
    ]
  })
}

# ===================================
# バックエンド用ロール
# ===================================
resource "aws_iam_role" "github_actions_backend" {
  for_each = toset(var.environments)
  
  name = "${var.project_name}-GitHubActions-Backend-${each.value}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_repository_backend}:ref:refs/heads/main",
              "repo:${var.github_repository_backend}:ref:refs/heads/develop"
            ]
          }
        }
      }
    ]
  })
}

# ===================================
# ポリシーアタッチメント
# ===================================

# Terraform実行用ポリシーをロールにアタッチ
resource "aws_iam_role_policy_attachment" "terraform_execution" {
  for_each = toset(var.environments)
  
  policy_arn = aws_iam_policy.terraform_execution[each.value].arn
  role       = aws_iam_role.github_actions[each.value].name
}

# 本番環境制限
resource "aws_iam_role_policy_attachment" "prod_restrictions" {
  count = contains(var.environments, "prod") ? 1 : 0
  
  policy_arn = aws_iam_policy.prod_restrictions[0].arn
  role       = aws_iam_role.github_actions["prod"].name
}

# フロントエンドデプロイ用ポリシーをロールにアタッチ
resource "aws_iam_role_policy_attachment" "frontend_deploy" {
  for_each = toset(var.environments)
  
  policy_arn = aws_iam_policy.frontend_deploy[each.value].arn
  role       = aws_iam_role.github_actions_frontend[each.value].name
}

# バックエンドデプロイ用ポリシー
resource "aws_iam_role_policy_attachment" "backend_deploy" {
  for_each = toset(var.environments)
  
  policy_arn = aws_iam_policy.backend_deploy[each.value].arn
  role       = aws_iam_role.github_actions_backend[each.value].name
}



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

