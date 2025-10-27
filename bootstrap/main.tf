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

# ===================================
# 事前準備: AWSアカウント情報の取得
# ===================================
# 
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
#
# 現在のアカウントIDを取得
data "aws_caller_identity" "current" {}

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
    Statement = [
      # ===================================
      # EC2関連
      # ===================================
      # 読み取り専用操作（安全なのでリソース制限なし）
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",        # 全ての情報取得（DescribeVpcs, DescribeSubnets等）
          "ec2:GetConsole*"       # コンソール出力取得
        ]
        Resource = "*"
      },

      # ===================================
      # VPC関連
      # ===================================
      # 書き込み操作（リソース作成・変更・削除）
      {
        Effect = "Allow"
        Action = [
          # VPC
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:ModifyVpcAttribute",
          
          # Subnet
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:ModifySubnetAttribute",
          
          # Route Table
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:ReplaceRoute",
          
          # Internet Gateway
          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          
          # NAT Gateway
          "ec2:CreateNatGateway",
          "ec2:DeleteNatGateway",
          
          # Elastic IP
          "ec2:AllocateAddress",
          "ec2:ReleaseAddress",
          "ec2:AssociateAddress",
          "ec2:DisassociateAddress",
          
          # Security Group
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:ModifySecurityGroupRules",
          
          # Network ACL
          "ec2:CreateNetworkAcl",
          "ec2:DeleteNetworkAcl",
          "ec2:CreateNetworkAclEntry",
          "ec2:DeleteNetworkAclEntry",
          "ec2:ReplaceNetworkAclEntry",
          "ec2:ReplaceNetworkAclAssociation",
          
          # VPC Endpoints
          "ec2:CreateVpcEndpoint",
          "ec2:DeleteVpcEndpoints",
          "ec2:ModifyVpcEndpoint",
          
          # Tags
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "*"
      },

      # ===================================
      # S3関連
      # ===================================
      # 1. 読み取り専用操作
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetObjectAttributes",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:GetBucketPolicy",
          "s3:GetBucketAcl",
          "s3:GetBucketCORS",
          "s3:GetBucketWebsite",
          "s3:GetLifecycleConfiguration",
          "s3:GetReplicationConfiguration",
          "s3:GetEncryptionConfiguration",
          "s3:ListBucket",
          "s3:ListBucketVersions",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${each.value}-*",
          "arn:aws:s3:::${var.project_name}-${each.value}-*/*"
        ]
      },

      # 2. 書き込み操作（バケット管理）
      {
        Effect = "Allow"
        Action = [
          # バケット作成・削除
          "s3:CreateBucket",
          "s3:DeleteBucket", # prod_restrictionsでDenyされる
          
          # バケット設定
          "s3:PutBucketVersioning",
          "s3:PutBucketAcl",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy", # prod_restrictionsでDenyされる
          "s3:PutBucketCORS",
          "s3:PutBucketWebsite",
          "s3:DeleteBucketWebsite",
          "s3:PutLifecycleConfiguration",
          "s3:PutReplicationConfiguration",
          "s3:PutEncryptionConfiguration",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketOwnershipControls",
          
          # バケット通知設定
          "s3:PutBucketNotification",
          "s3:GetBucketNotification",
          
          # タグ管理
          "s3:PutBucketTagging",
          "s3:GetBucketTagging"
        ]
        Resource = "arn:aws:s3:::${var.project_name}-${each.value}-*"
      },

      # 3. オブジェクト操作
      {
        Effect = "Allow"
        Action = [
          # オブジェクト書き込み
          "s3:PutObject",
          "s3:PutObjectAcl",
          
          # オブジェクト削除（prod_restrictionsでDenyされる）
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          
          # マルチパートアップロード
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = "arn:aws:s3:::${var.project_name}-${each.value}-*/*"
      },

      # ===================================
      # IAM関連
      # ===================================
      # 1. 読み取り専用操作
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:GetInstanceProfile",
          "iam:ListRoles",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListPolicies",
          "iam:ListPolicyVersions",
          "iam:ListInstanceProfiles",
          "iam:ListInstanceProfilesForRole"
        ]
        Resource = "*"  # 読み取りなので全体を許可
      },

      # 2. ロール管理（プロジェクト名とアカウントIDで制限）
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:UpdateRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:TagRole",
          "iam:UntagRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"
        ]
      },

      # 3. ポリシー管理（プロジェクト名とアカウントIDで制限）
      {
        Effect = "Allow"
        Action = [
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:SetDefaultPolicyVersion",
          "iam:TagPolicy",
          "iam:UntagPolicy"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project_name}-*"
        ]
      },

      # 4. ポリシーアタッチ（特定ポリシーのみ許可）
      {
        Effect = "Allow"
        Action = [
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"
        ]
        Condition = {
          ArnLike = {
            # プロジェクト管理下のポリシーまたは特定のAWSマネージドポリシーのみ
            "iam:PolicyARN": [
              "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project_name}-*",
              "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
              "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
              "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
            ]
          }
        }
      },

      # 5. PassRole（特定サービスのみ許可）
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"
        ]
        Condition = {
          StringEquals = {
            # PassRoleを許可するサービスを限定
            "iam:PassedToService": [
              "lambda.amazonaws.com",
              "ecs-tasks.amazonaws.com",
              "ec2.amazonaws.com",
              "rds.amazonaws.com",
              "amplify.amazonaws.com"
            ]
          }
        }
      },

      # 6. インスタンスプロファイル管理
      {
        Effect = "Allow"
        Action = [
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.project_name}-*"
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

resource "aws_iam_role_policy_attachment" "prod_restrictions" {
  count = contains(var.environments, "prod") ? 1 : 0
  
  policy_arn = aws_iam_policy.prod_restrictions[0].arn
  role       = aws_iam_role.github_actions["prod"].name
}

# S3アプリデプロイ用のポリシー
# これはアプリケーションリポジトリからのCI/CDデプロイ用
# github actionsからawsを操作する場合のポリシー
resource "aws_iam_policy" "app_deploy" {
  for_each = toset(var.environments)
  
  name        = "${var.project_name}-AppDeploy-${each.value}"
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