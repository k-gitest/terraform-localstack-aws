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