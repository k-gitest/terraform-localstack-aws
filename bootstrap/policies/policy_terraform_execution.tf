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
    )

    Statement = [
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

      # ===================================
      # ALB/ELB関連
      # ===================================

      # 1. 読み取り専用操作
      {
        Effect = "Allow"
        Action = [
          # ロードバランサー
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          
          # ターゲットグループ
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          
          # リスナー
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          
          # ルール
          "elasticloadbalancing:DescribeRules",
          
          # SSL証明書
          "elasticloadbalancing:DescribeSSLPolicies",
          
          # タグ
          "elasticloadbalancing:DescribeTags",
          
          # アカウント制限
          "elasticloadbalancing:DescribeAccountLimits"
        ]
        Resource = "*"  # 読み取りなので全体を許可
      },

      # 2. ロードバランサー管理
      {
        Effect = "Allow"
        Action = [
          # ロードバランサー作成・削除
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:DeleteLoadBalancer",  # prod_restrictionsでDenyされる
          
          # ロードバランサー設定
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          
          # タグ管理
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:loadbalancer/app/${var.project_name}-*",
          "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:loadbalancer/net/${var.project_name}-*"
        ]
      },

      # 3. ターゲットグループ管理
      {
        Effect = "Allow"
        Action = [
          # ターゲットグループ作成・削除
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteTargetGroup",  # prod_restrictionsでDenyされる
          
          # ターゲットグループ設定
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          
          # ターゲット登録・解除
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          
          # タグ管理
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:targetgroup/${var.project_name}-*"
        ]
      },

      # 4. リスナー管理
      {
        Effect = "Allow"
        Action = [
          # リスナー作成・削除
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          
          # リスナー設定
          "elasticloadbalancing:ModifyListener",
          
          # SSL証明書管理
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener/app/${var.project_name}-*",
          "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener/net/${var.project_name}-*"
        ]
      },

      # 5. リスナールール管理
      {
        Effect = "Allow"
        Action = [
          # ルール作成・削除
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule",
          
          # ルール設定
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:SetRulePriorities",
          
          # タグ管理
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener-rule/app/${var.project_name}-*",
          "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:listener-rule/net/${var.project_name}-*"
        ]
      },

      # 6. ターゲット登録時の追加権限（EC2/ECS用）
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:targetgroup/${var.project_name}-*"
        ]
        Condition = {
          StringEquals = {
            # 特定のターゲットタイプのみ許可
            "elasticloadbalancing:TargetType": [
              "instance",  # EC2インスタンス
              "ip"         # ECS Fargate
            ]
          }
        }
      },

      # ===================================
      # CloudFront関連
      # ===================================

      # 1. 読み取り専用操作
      {
        Effect = "Allow"
        Action = [
          # ディストリビューション
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          "cloudfront:ListDistributions",
          "cloudfront:ListDistributionsByWebACLId",
          
          # キャッシュポリシー
          "cloudfront:GetCachePolicy",
          "cloudfront:GetCachePolicyConfig",
          "cloudfront:ListCachePolicies",
          
          # オリジンリクエストポリシー
          "cloudfront:GetOriginRequestPolicy",
          "cloudfront:GetOriginRequestPolicyConfig",
          "cloudfront:ListOriginRequestPolicies",
          
          # レスポンスヘッダーポリシー
          "cloudfront:GetResponseHeadersPolicy",
          "cloudfront:GetResponseHeadersPolicyConfig",
          "cloudfront:ListResponseHeadersPolicies",
          
          # Origin Access Control (OAC)
          "cloudfront:GetOriginAccessControl",
          "cloudfront:GetOriginAccessControlConfig",
          "cloudfront:ListOriginAccessControls",
          
          # Invalidation（キャッシュクリア）
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations",
          
          # CloudFront Functions
          "cloudfront:DescribeFunction",
          "cloudfront:ListFunctions",
          
          # タグ
          "cloudfront:ListTagsForResource"
        ]
        Resource = "*"  # 読み取りなので全体を許可
      },

      # 2. ディストリビューション作成（タグ付与を強制）
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateDistribution"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/Project": var.project_name
            "aws:RequestTag/ManagedBy": "terraform"
          }
        }
      },

      # 3. ディストリビューション更新・削除（プロジェクトタグでフィルタ）
      {
        Effect = "Allow"
        Action = [
          "cloudfront:UpdateDistribution",
          "cloudfront:DeleteDistribution",  # prod_restrictionsでDenyされる
          "cloudfront:TagResource",
          "cloudfront:UntagResource"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Project": var.project_name
          }
        }
      },

      # 4. キャッシュポリシー管理
      # frontend_deployで管理するため、ここでは除外
      # {
      #   Effect = "Allow"
      #   Action = [
      #     "cloudfront:CreateCachePolicy",
      #     "cloudfront:UpdateCachePolicy",
      #     "cloudfront:DeleteCachePolicy"
      #   ]
      #   Resource = [
      #     "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:cache-policy/*"
      #   ]
      # },

      # 5. オリジンリクエストポリシー管理
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateOriginRequestPolicy",
          "cloudfront:UpdateOriginRequestPolicy",
          "cloudfront:DeleteOriginRequestPolicy"
        ]
        Resource = [
          "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:origin-request-policy/*"
        ]
      },

      # 6. レスポンスヘッダーポリシー管理
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateResponseHeadersPolicy",
          "cloudfront:UpdateResponseHeadersPolicy",
          "cloudfront:DeleteResponseHeadersPolicy"
        ]
        Resource = [
          "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:response-headers-policy/*"
        ]
      },

      # 7. Origin Access Control (OAC) 管理
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateOriginAccessControl",
          "cloudfront:UpdateOriginAccessControl",
          "cloudfront:DeleteOriginAccessControl"
        ]
        Resource = [
          "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:origin-access-control/*"
        ]
      },

      # 8. CloudFront Functions管理
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateFunction",
          "cloudfront:UpdateFunction",
          "cloudfront:DeleteFunction",
          "cloudfront:PublishFunction",
          "cloudfront:TestFunction"
        ]
        Resource = [
          "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:function/*"
        ]
      },

      # ===================================
      # Amplify関連
      # ===================================

      # 1. 読み取り専用操作
      {
        Effect = "Allow"
        Action = [
          # アプリ
          "amplify:GetApp",
          "amplify:ListApps",
          
          # ブランチ
          "amplify:GetBranch",
          "amplify:ListBranches",
          
          # ジョブ（ビルド・デプロイ）
          "amplify:GetJob",
          "amplify:ListJobs",
          
          # ドメイン
          "amplify:GetDomainAssociation",
          "amplify:ListDomainAssociations",
          
          # Webhook
          "amplify:GetWebhook",
          "amplify:ListWebhooks",
          
          # バックエンド環境
          "amplify:GetBackendEnvironment",
          "amplify:ListBackendEnvironments",
          
          # アーティファクト
          "amplify:GetArtifactUrl",
          "amplify:ListArtifacts",
          
          # タグ
          "amplify:ListTagsForResource"
        ]
        Resource = "*"  # 読み取りなので全体を許可
      },

      # 2. アプリ作成（タグ必須）
      {
        Effect = "Allow"
        Action = [
          "amplify:CreateApp"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/Project": var.project_name
            "aws:RequestTag/ManagedBy": "terraform"
          }
        }
      },

      # 3. アプリ更新・削除（タグフィルタ）
      {
        Effect = "Allow"
        Action = [
          "amplify:UpdateApp",
          "amplify:DeleteApp",  # prod_restrictionsでDenyされる
          "amplify:TagResource",
          "amplify:UntagResource"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Project": var.project_name
          }
        }
      },

      # 4. ブランチ管理
      {
        Effect = "Allow"
        Action = [
          # ブランチ作成・更新・削除
          "amplify:CreateBranch",
          "amplify:UpdateBranch",
          "amplify:DeleteBranch",  # prod_restrictionsでDenyされる
          
          # ビルド・デプロイ
          "amplify:StartJob",
          "amplify:StopJob"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            # アプリのタグでフィルタ（ブランチ自体にはタグが付けられない）
            "aws:ResourceTag/Project": var.project_name
          }
        }
      },

      # 5. ドメイン管理
      {
        Effect = "Allow"
        Action = [
          # ドメイン関連付け
          "amplify:CreateDomainAssociation",
          "amplify:UpdateDomainAssociation",
          "amplify:DeleteDomainAssociation"
        ]
        Resource = [
          "arn:aws:amplify:*:${data.aws_caller_identity.current.account_id}:apps/${var.project_name}-*/domains/*"
        ]
      },

      # 6. Webhook管理
      {
        Effect = "Allow"
        Action = [
          # Webhook作成・更新・削除
          "amplify:CreateWebhook",
          "amplify:UpdateWebhook",
          "amplify:DeleteWebhook"
        ]
        Resource = [
          "arn:aws:amplify:*:${data.aws_caller_identity.current.account_id}:apps/${var.project_name}-*/webhooks/*"
        ]
      },

      # 7. バックエンド環境管理
      {
        Effect = "Allow"
        Action = [
          # バックエンド環境作成・削除
          "amplify:CreateBackendEnvironment",
          "amplify:UpdateBackendEnvironment",
          "amplify:DeleteBackendEnvironment"
        ]
        Resource = [
          "arn:aws:amplify:*:${data.aws_caller_identity.current.account_id}:apps/${var.project_name}-*/backendenvironments/*"
        ]
      },

      # 8. デプロイメント管理
      {
        Effect = "Allow"
        Action = [
          # デプロイメント作成
          "amplify:CreateDeployment",
          
          # ビルド開始・停止
          "amplify:StartJob",
          "amplify:StopJob",
          "amplify:StartDeployment"
        ]
        Resource = [
          "arn:aws:amplify:*:${data.aws_caller_identity.current.account_id}:apps/${var.project_name}-*/*"
        ]
      },

      # 9. IAM PassRole（Amplifyサービスロール用）
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*-amplify-role"
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService": "amplify.amazonaws.com"
          }
        }
      },

      # ===================================
      # CloudWatch Logs関連
      # ===================================

      # 1. 読み取り専用操作
      {
        Effect = "Allow"
        Action = [
          # ロググループ
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:ListTagsLogGroup",
          
          # ログイベント
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          
          # クエリ
          "logs:DescribeQueries",
          "logs:GetQueryResults",
          "logs:StartQuery",
          "logs:StopQuery",
          
          # メトリクスフィルタ
          "logs:DescribeMetricFilters",
          
          # サブスクリプションフィルタ
          "logs:DescribeSubscriptionFilters",
          
          # リソースポリシー
          "logs:DescribeResourcePolicies",
          
          # エクスポートタスク
          "logs:DescribeExportTasks"
        ]
        Resource = "*"  # 読み取りなので全体を許可
      },

      # 2. ロググループ管理
      {
        Effect = "Allow"
        Action = [
          # ロググループ作成・削除
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",  # prod_restrictionsでDenyされる
          
          # 保持期間設定
          "logs:PutRetentionPolicy",
          "logs:DeleteRetentionPolicy",
          
          # タグ管理
          "logs:TagLogGroup",
          "logs:UntagLogGroup"
        ]
        Resource = [
          # ロググループの操作には:*が必要な場合と不要な場合がある
          # 安全のため両方を含める
          # Lambda用
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*:*",
          
          # ECS用
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-*:*",
          
          # カスタムログ用
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/${var.project_name}/*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/${var.project_name}/*:*"
        ]
      },

      # 3. ログストリーム管理
      {
        Effect = "Allow"
        Action = [
          # ログストリーム作成・削除
          "logs:CreateLogStream",
          "logs:DeleteLogStream",
          
          # ログイベント書き込み
          "logs:PutLogEvents"
        ]
        Resource = [
          # Lambda用
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*:log-stream:*",
          
          # ECS用
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-*:log-stream:*",
          
          # カスタムログ用
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/${var.project_name}/*:log-stream:*"
        ]
      },

      # 4. メトリクスフィルタ管理
      {
        Effect = "Allow"
        Action = [
          "logs:PutMetricFilter",
          "logs:DeleteMetricFilter"
        ]
        Resource = [
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/${var.project_name}/*"
        ]
      },

      # 5. サブスクリプションフィルタ管理
      {
        Effect = "Allow"
        Action = [
          "logs:PutSubscriptionFilter",
          "logs:DeleteSubscriptionFilter"
        ]
        Resource = [
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-*",
          "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/${var.project_name}/*"
        ]
      },

      # 6. リソースポリシー管理
      {
        Effect = "Allow"
        Action = [
          "logs:PutResourcePolicy",
          "logs:DeleteResourcePolicy"
        ]
        Resource = "*"  # リソースポリシーはグローバル
      },
      
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