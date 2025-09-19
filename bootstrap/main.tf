# GitHub Actions OIDCプロバイダーとロールのセットアップ
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

# OIDCサーバー証明書のサムプリントをopenID Connectプロバイダーで使用するために取得
data "tls_certificate" "github_actions_deploy" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

# GitHub OIDC プロバイダー
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

# 各環境用のIAMロール
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

# Terraform実行用のポリシー
resource "aws_iam_policy" "terraform_execution" {
  for_each = toset(var.environments)
  
  name        = "${var.project_name}-TerraformExecution-${each.value}"
  description = "Terraform実行用ポリシー for ${each.value} environment"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # EC2関連
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
        ]
        Resource = "*"
      },
      # VPC関連
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateVpc*",
          "ec2:DeleteVpc*",
          "ec2:ModifyVpc*",
          "ec2:DescribeVpc*",
          "ec2:CreateSubnet*",
          "ec2:DeleteSubnet*",
          "ec2:ModifySubnet*",
          "ec2:DescribeSubnet*",
          "ec2:CreateRouteTable*",
          "ec2:DeleteRouteTable*",
          "ec2:ModifyRouteTable*",
          "ec2:DescribeRouteTable*",
          "ec2:CreateRoute*",
          "ec2:DeleteRoute*",
          "ec2:CreateInternetGateway*",
          "ec2:DeleteInternetGateway*",
          "ec2:AttachInternetGateway*",
          "ec2:DetachInternetGateway*",
          "ec2:DescribeInternetGateway*",
          "ec2:CreateSecurityGroup*",
          "ec2:DeleteSecurityGroup*",
          "ec2:ModifySecurityGroup*",
          "ec2:DescribeSecurityGroup*",
          "ec2:AuthorizeSecurityGroup*",
          "ec2:RevokeSecurityGroup*"
        ]
        Resource = "*"
      },
      # S3関連
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-*",
          "arn:aws:s3:::${var.project_name}-*/*"
        ]
      },
      # IAM関連（制限付き）
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:PassRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:ListPolicies",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile"
        ]
        Resource = [
          "arn:aws:iam::*:role/${var.project_name}-*",
          "arn:aws:iam::*:policy/${var.project_name}-*",
          "arn:aws:iam::*:instance-profile/${var.project_name}-*"
        ]
      },
      # Lambda関連
      {
        Effect = "Allow"
        Action = [
          "lambda:*"
        ]
        Resource = "*"
      },
      # ECS関連
      {
        Effect = "Allow"
        Action = [
          "ecs:*",
          "ecr:*"
        ]
        Resource = "*"
      },
      # RDS関連
      {
        Effect = "Allow"
        Action = [
          "rds:*"
        ]
        Resource = "*"
      },
      # ALB関連
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      },
      # CloudFront関連
      {
        Effect = "Allow"
        Action = [
          "cloudfront:*"
        ]
        Resource = "*"
      },
      # Amplify関連
      {
        Effect = "Allow"
        Action = [
          "amplify:*"
        ]
        Resource = "*"
      },
      # CloudWatch Logs関連
      {
        Effect = "Allow"
        Action = [
          "logs:*"
        ]
        Resource = "*"
      },
      # Systems Manager関連
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "*"
      },
      # Route53関連
      {
        Effect = "Allow"
        Action = [
          "route53:*"
        ]
        Resource = "*"
      },
      # Certificate Manager関連
      {
        Effect = "Allow"
        Action = [
          "acm:*"
        ]
        Resource = "*"
      },
      # その他必要な権限
      {
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity",
          "sts:AssumeRole"
        ]
        Resource = "*"
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

# ポリシーをロールにアタッチ
resource "aws_iam_role_policy_attachment" "terraform_execution" {
  for_each = toset(var.environments)
  
  policy_arn = aws_iam_policy.terraform_execution[each.value].arn
  role       = aws_iam_role.github_actions[each.value].name
}

# 本番環境には追加の制限を設ける場合
resource "aws_iam_policy" "prod_restrictions" {
  count = contains(var.environments, "prod") ? 1 : 0
  
  name        = "${var.project_name}-ProdRestrictions"
  description = "本番環境での追加制限ポリシー"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "prod_restrictions" {
  count = contains(var.environments, "prod") ? 1 : 0
  
  policy_arn = aws_iam_policy.prod_restrictions[0].arn
  role       = aws_iam_role.github_actions["prod"].name
}

# s3 アプリデプロイ用のポリシー
resource "aws_iam_policy" "app_deploy" {
  for_each = toset(var.environments)
  
  name        = "${var.project_name}-AppDeploy-${each.value}"
  description = "アプリケーションデプロイ用ポリシー for ${each.value} environment"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3バケットへのデプロイ権限
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${each.value}-*",
          "arn:aws:s3:::${var.project_name}-${each.value}-*/*"
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
    Name        = "${var.project_name}-AppDeploy-${each.value}"
    Environment = each.value
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# アプリデプロイポリシーをロールにアタッチ
resource "aws_iam_role_policy_attachment" "app_deploy" {
  for_each = toset(var.environments)
  
  policy_arn = aws_iam_policy.app_deploy[each.value].arn
  role       = aws_iam_role.github_actions[each.value].name
}