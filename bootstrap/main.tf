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

# terraform実行各環境用のIAMロール
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

      # ===================================
      # Lambda関連
      # ===================================

      # 1. 読み取り専用操作
      {
        Effect = "Allow"
        Action = [
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:GetFunctionConcurrency",
          "lambda:GetFunctionEventInvokeConfig",
          "lambda:GetPolicy",
          "lambda:GetLayerVersion",
          "lambda:GetLayerVersionPolicy",
          "lambda:ListFunctions",
          "lambda:ListVersionsByFunction",
          "lambda:ListAliases",
          "lambda:ListLayers",
          "lambda:ListLayerVersions",
          "lambda:ListTags",
          "lambda:ListEventSourceMappings"
        ]
        Resource = "*"  # 読み取りなので全体を許可
      },

      # 2. 関数の作成・更新・削除
      {
        Effect = "Allow"
        Action = [
          # 関数管理
          "lambda:CreateFunction",
          "lambda:DeleteFunction",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:PublishVersion",
          
          # エイリアス管理
          "lambda:CreateAlias",
          "lambda:UpdateAlias",
          "lambda:DeleteAlias",
          
          # タグ管理
          "lambda:TagResource",
          "lambda:UntagResource"
        ]
        Resource = [
          "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*"
        ]
      },

      # 3. Lambda実行権限の設定
      {
        Effect = "Allow"
        Action = [
          "lambda:AddPermission",
          "lambda:RemovePermission"
        ]
        Resource = [
          "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*"
        ]
      },

      # 4. 環境変数・VPC設定
      {
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionConfiguration"
        ]
        Resource = [
          "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*"
        ]
      },

      # 5. イベントソースマッピング（S3, SQS等とのトリガー連携）
      {
        Effect = "Allow"
        Action = [
          "lambda:CreateEventSourceMapping",
          "lambda:UpdateEventSourceMapping",
          "lambda:DeleteEventSourceMapping"
        ]
        Resource = "*"  # イベントソースマッピングはARNパターンが複雑
      },

      # 6. Lambda Layer管理
      {
        Effect = "Allow"
        Action = [
          "lambda:PublishLayerVersion",
          "lambda:DeleteLayerVersion",
          "lambda:AddLayerVersionPermission",
          "lambda:RemoveLayerVersionPermission"
        ]
        Resource = [
          "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:layer:${var.project_name}-*"
        ]
      },

      # 7. 同時実行数の設定
      {
        Effect = "Allow"
        Action = [
          "lambda:PutFunctionConcurrency",
          "lambda:DeleteFunctionConcurrency"
        ]
        Resource = [
          "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*"
        ]
      },

      # 8. CloudWatch Logs権限（Lambdaログ用）
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:DeleteLogGroup"
        ]
        Resource = [
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*:*"
        ]
      },

      # ===================================
      # ECS関連
      # ===================================

      # 1. 読み取り専用操作
      {
        Effect = "Allow"
        Action = [
          # クラスター
          "ecs:DescribeClusters",
          "ecs:ListClusters",
          
          # サービス
          "ecs:DescribeServices",
          "ecs:ListServices",
          
          # タスク
          "ecs:DescribeTasks",
          "ecs:DescribeTaskDefinition",
          "ecs:ListTasks",
          "ecs:ListTaskDefinitions",
          "ecs:ListTaskDefinitionFamilies",
          
          # コンテナインスタンス
          "ecs:DescribeContainerInstances",
          "ecs:ListContainerInstances",
          
          # その他
          "ecs:ListAttributes",
          "ecs:ListAccountSettings",
          "ecs:DescribeCapacityProviders",
          "ecs:ListTagsForResource"
        ]
        Resource = "*"  # 読み取りなので全体を許可
      },

      # 2. クラスター管理
      {
        Effect = "Allow"
        Action = [
          "ecs:CreateCluster",
          "ecs:DeleteCluster",
          "ecs:UpdateCluster",
          "ecs:PutClusterCapacityProviders",
          "ecs:TagResource",
          "ecs:UntagResource"
        ]
        Resource = [
          "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:cluster/${var.project_name}-*"
        ]
      },

      # 3. タスク定義管理
      {
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DeregisterTaskDefinition",
          "ecs:TagResource"
        ]
        Resource = "*"  # タスク定義はARNに名前が含まれないため
      },

      # 4. サービス管理
      {
        Effect = "Allow"
        Action = [
          "ecs:CreateService",
          "ecs:UpdateService",
          "ecs:DeleteService",
          "ecs:TagResource",
          "ecs:UntagResource"
        ]
        Resource = [
          "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:service/${var.project_name}-*/*"
        ]
      },

      # 5. タスク実行
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask",
          "ecs:StartTask",
          "ecs:StopTask",
          "ecs:UpdateTaskSet",
          "ecs:DeleteTaskSet"
        ]
        Resource = [
          "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:task/${var.project_name}-*/*",
          "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:task-definition/${var.project_name}-*:*"
        ]
      },

      # 6. キャパシティプロバイダー管理
      {
        Effect = "Allow"
        Action = [
          "ecs:CreateCapacityProvider",
          "ecs:UpdateCapacityProvider",
          "ecs:DeleteCapacityProvider"
        ]
        Resource = [
          "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:capacity-provider/${var.project_name}-*"
        ]
      },

      # 7. IAM PassRole（ECSタスク実行用）
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*-ecs-*"
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService": [
              "ecs-tasks.amazonaws.com"
            ]
          }
        }
      },

      # ===================================
      # ECR関連
      # ===================================

      # 8. ECR読み取り専用操作
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:ListImages",
          "ecr:ListTagsForResource",
          "ecr:GetRepositoryPolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview"
        ]
        Resource = [
          "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-*"
        ]
      },

      # 9. ECR認証トークン取得
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"  # GetAuthorizationTokenはリソース指定不可
      },

      # 10. ECRリポジトリ管理
      {
        Effect = "Allow"
        Action = [
          "ecr:CreateRepository",
          "ecr:DeleteRepository",
          "ecr:PutRepositoryPolicy",
          "ecr:DeleteRepositoryPolicy",
          "ecr:SetRepositoryPolicy",
          "ecr:PutLifecyclePolicy",
          "ecr:DeleteLifecyclePolicy",
          "ecr:PutImageTagMutability",
          "ecr:PutImageScanningConfiguration",
          "ecr:TagResource",
          "ecr:UntagResource"
        ]
        Resource = [
          "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-*"
        ]
      },

      # 11. ECRイメージ管理
      {
        Effect = "Allow"
        Action = [
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:BatchDeleteImage"
        ]
        Resource = [
          "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-*"
        ]
      },

      # 12. CloudWatch Logs（ECSタスクログ用）
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:DeleteLogGroup"
        ]
        Resource = [
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-*:*"
        ]
      },

      # ===================================
      # RDS関連
      # ===================================

      # 1. 読み取り専用操作
      {
        Effect = "Allow"
        Action = [
          # インスタンス情報
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBClusterSnapshots",
          "rds:DescribeDBSnapshots",
          
          # パラメータグループ
          "rds:DescribeDBParameterGroups",
          "rds:DescribeDBParameters",
          "rds:DescribeDBClusterParameterGroups",
          "rds:DescribeDBClusterParameters",
          
          # オプショングループ
          "rds:DescribeOptionGroups",
          "rds:DescribeOptionGroupOptions",
          
          # サブネットグループ
          "rds:DescribeDBSubnetGroups",
          
          # セキュリティグループ
          "rds:DescribeDBSecurityGroups",
          
          # その他
          "rds:DescribeDBEngineVersions",
          "rds:DescribeOrderableDBInstanceOptions",
          "rds:DescribeEventCategories",
          "rds:DescribeEventSubscriptions",
          "rds:DescribeEvents",
          "rds:ListTagsForResource"
        ]
        Resource = "*"  # 読み取りなので全体を許可
      },

      # 2. DBインスタンス管理
      {
        Effect = "Allow"
        Action = [
          # インスタンス作成・変更
          "rds:CreateDBInstance",
          "rds:ModifyDBInstance",
          "rds:DeleteDBInstance",  # prod_restrictionsでDenyされる
          "rds:RebootDBInstance",
          "rds:StartDBInstance",
          "rds:StopDBInstance",
          
          # タグ管理
          "rds:AddTagsToResource",
          "rds:RemoveTagsFromResource"
        ]
        Resource = [
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:db:${var.project_name}-*"
        ]
      },

      # 3. DBクラスター管理（Aurora用）
      {
        Effect = "Allow"
        Action = [
          # クラスター作成・変更
          "rds:CreateDBCluster",
          "rds:ModifyDBCluster",
          "rds:DeleteDBCluster",  # prod_restrictionsでDenyされる
          "rds:StartDBCluster",
          "rds:StopDBCluster",
          
          # クラスターインスタンス
          "rds:CreateDBInstance",
          "rds:DeleteDBInstance",
          
          # タグ管理
          "rds:AddTagsToResource",
          "rds:RemoveTagsFromResource"
        ]
        Resource = [
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:cluster:${var.project_name}-*",
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:db:${var.project_name}-*"
        ]
      },

      # 4. スナップショット管理
      {
        Effect = "Allow"
        Action = [
          # スナップショット作成・削除
          "rds:CreateDBSnapshot",
          "rds:DeleteDBSnapshot",
          "rds:CreateDBClusterSnapshot",
          "rds:DeleteDBClusterSnapshot",
          
          # スナップショット復元
          "rds:RestoreDBInstanceFromDBSnapshot",
          "rds:RestoreDBClusterFromSnapshot",
          
          # スナップショットコピー
          "rds:CopyDBSnapshot",
          "rds:CopyDBClusterSnapshot",
          
          # タグ管理
          "rds:AddTagsToResource",
          "rds:RemoveTagsFromResource"
        ]
        Resource = [
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:snapshot:${var.project_name}-*",
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:cluster-snapshot:${var.project_name}-*"
        ]
      },

      # 5. パラメータグループ管理
      {
        Effect = "Allow"
        Action = [
          "rds:CreateDBParameterGroup",
          "rds:ModifyDBParameterGroup",
          "rds:DeleteDBParameterGroup",
          "rds:ResetDBParameterGroup",
          
          "rds:CreateDBClusterParameterGroup",
          "rds:ModifyDBClusterParameterGroup",
          "rds:DeleteDBClusterParameterGroup",
          "rds:ResetDBClusterParameterGroup",
          
          "rds:AddTagsToResource",
          "rds:RemoveTagsFromResource"
        ]
        Resource = [
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:pg:${var.project_name}-*",
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:cluster-pg:${var.project_name}-*"
        ]
      },

      # 6. オプショングループ管理
      {
        Effect = "Allow"
        Action = [
          "rds:CreateOptionGroup",
          "rds:ModifyOptionGroup",
          "rds:DeleteOptionGroup",
          "rds:AddTagsToResource",
          "rds:RemoveTagsFromResource"
        ]
        Resource = [
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:og:${var.project_name}-*"
        ]
      },

      # 7. サブネットグループ管理
      {
        Effect = "Allow"
        Action = [
          "rds:CreateDBSubnetGroup",
          "rds:ModifyDBSubnetGroup",
          "rds:DeleteDBSubnetGroup",
          "rds:AddTagsToResource",
          "rds:RemoveTagsFromResource"
        ]
        Resource = [
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:subgrp:${var.project_name}-*"
        ]
      },

      # 8. イベントサブスクリプション管理
      {
        Effect = "Allow"
        Action = [
          "rds:CreateEventSubscription",
          "rds:ModifyEventSubscription",
          "rds:DeleteEventSubscription",
          "rds:AddTagsToResource",
          "rds:RemoveTagsFromResource"
        ]
        Resource = [
          "arn:aws:rds:*:${data.aws_caller_identity.current.account_id}:es:${var.project_name}-*"
        ]
      },

      # 9. IAM PassRole（RDS拡張モニタリング用）
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*-rds-monitoring-role"
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService": [
              "monitoring.rds.amazonaws.com"
            ]
          }
        }
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

# アプリデプロイポリシーをロールにポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "frontend_deploy" {
  for_each = toset(var.environments)
  
  policy_arn = aws_iam_policy.frontend_deploy[each.value].arn
  role       = aws_iam_role.github_actions_frontend[each.value].name
}

resource "aws_iam_role_policy_attachment" "backend_deploy" {
  for_each = toset(var.environments)
  
  policy_arn = aws_iam_policy.backend_deploy[each.value].arn
  role       = aws_iam_role.github_actions_backend[each.value].name
}