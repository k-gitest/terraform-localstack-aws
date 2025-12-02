# ===================================
# ECR/ECS関連ポリシー定義（環境分離・セキュリティ強化版）
# ===================================

locals {
  # ===================================
  # 共通ステートメント（読み取り専用）
  # ===================================
  ecs_ecr_common_statements = [
    {
      Sid      = "ECSReadAccess"
      Effect   = "Allow"
      Action   = [
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
      Resource = "*" 
    },
    {
      Sid      = "ECRReadAccess"
      Effect   = "Allow"
      Action   = [
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
      Resource = "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-*"
    },
    {
      Sid      = "ECRAuthToken"
      Effect   = "Allow"
      Action   = [
        "ecr:GetAuthorizationToken"
      ]
      Resource = "*" 
    }
  ]
  
  # ===================================
  # 開発環境専用ステートメント（dev-* リソースへのフル管理）
  # ===================================
  ecs_ecr_dev_management_statements = [
    # ECS クラスター管理（削除含む）
    {
      Sid    = "ClusterManagementDev"
      Effect = "Allow"
      Action = [
        "ecs:CreateCluster",
        "ecs:DeleteCluster",
        "ecs:UpdateCluster",
        "ecs:PutClusterCapacityProviders",
        "ecs:TagResource",
        "ecs:UntagResource"
      ]
      Resource = "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:cluster/${var.project_name}-dev-*"
    },
    # ECS タスク定義管理（Deregister含む）
    {
      Sid    = "TaskDefinitionManagementDev"
      Effect = "Allow"
      Action = [
        "ecs:RegisterTaskDefinition",
        "ecs:DeregisterTaskDefinition",
        "ecs:TagResource"
      ]
      Resource = "*" 
    },
    # ECS サービス管理（削除含む）
    {
      Sid    = "ServiceManagementDev"
      Effect = "Allow"
      Action = [
        "ecs:CreateService",
        "ecs:UpdateService",
        "ecs:DeleteService",
        "ecs:TagResource",
        "ecs:UntagResource"
      ]
      Resource = "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:service/${var.project_name}-dev-*/*"
    },
    # ECS タスク実行（停止含む）
    {
      Sid    = "TaskExecutionDev"
      Effect = "Allow"
      Action = [
        "ecs:RunTask",
        "ecs:StartTask",
        "ecs:StopTask",
        "ecs:UpdateTaskSet",
        "ecs:DeleteTaskSet"
      ]
      Resource = [
        "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:task/${var.project_name}-dev-*/*",
        "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:task-definition/${var.project_name}-dev-*:*"
      ]
    },
    # ECS キャパシティプロバイダー管理（削除含む）
    {
      Sid    = "CapacityProviderManagementDev"
      Effect = "Allow"
      Action = [
        "ecs:CreateCapacityProvider",
        "ecs:UpdateCapacityProvider",
        "ecs:DeleteCapacityProvider"
      ]
      Resource = "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:capacity-provider/${var.project_name}-dev-*"
    },
    # IAM PassRole（ECSタスク実行用 - dev-* ロールが対象）
    {
      Sid    = "PassRoleECSDev"
      Effect = "Allow"
      Action = [
        "iam:PassRole"
      ]
      Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-dev-*-ecs-*"
      Condition = {
        StringEquals = {
          "iam:PassedToService": [
            "ecs-tasks.amazonaws.com"
          ]
        }
      }
    },
    # ECR リポジトリ管理（削除、ポリシー削除含む）
    {
      Sid    = "ECRRepoManagementDev"
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
      Resource = "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-dev-*"
    },
    # ECR イメージ管理（削除含む）
    {
      Sid    = "ECRImageManagementDev"
      Effect = "Allow"
      Action = [
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:BatchDeleteImage"
      ]
      Resource = "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-dev-*"
    },
    # CloudWatch Logs（ECSタスクログ用 - ロググループ削除含む）
    {
      Sid    = "ECSLogsManagementDev"
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
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-dev-*",
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-dev-*:*"
      ]
    }
  ]
  
  # ===================================
  # 本番環境専用ステートメント（prod-* リソースへの作成・変更のみ）
  # ===================================
  ecs_ecr_prod_management_statements = [
    # ECS クラスター管理（作成/更新のみ - 削除系アクションを意図的に除外）
    {
      Sid    = "ClusterManagementProd"
      Effect = "Allow"
      Action = [
        "ecs:CreateCluster",
        "ecs:UpdateCluster",
        "ecs:PutClusterCapacityProviders",
        "ecs:TagResource",
        "ecs:UntagResource"
      ]
      Resource = "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:cluster/${var.project_name}-prod-*"
    },
    # ECS タスク定義管理（Deregisterを意図的に除外）
    {
      Sid    = "TaskDefinitionManagementProd"
      Effect = "Allow"
      Action = [
        "ecs:RegisterTaskDefinition",
        "ecs:TagResource"
      ]
      Resource = "*" 
    },
    # ECS サービス管理（作成/更新のみ - 削除系アクションを意図的に除外）
    {
      Sid    = "ServiceManagementProd"
      Effect = "Allow"
      Action = [
        "ecs:CreateService",
        "ecs:UpdateService",
        "ecs:TagResource",
        "ecs:UntagResource"
      ]
      Resource = "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:service/${var.project_name}-prod-*/*"
    },
    # ECS タスク実行（停止を意図的に除外）
    {
      Sid    = "TaskExecutionProd"
      Effect = "Allow"
      Action = [
        "ecs:RunTask",
        "ecs:StartTask",
        "ecs:UpdateTaskSet"
      ]
      Resource = [
        "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:task/${var.project_name}-prod-*/*",
        "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:task-definition/${var.project_name}-prod-*:*"
      ]
    },
    # ECS キャパシティプロバイダー管理（作成/更新のみ - 削除系アクションを意図的に除外）
    {
      Sid    = "CapacityProviderManagementProd"
      Effect = "Allow"
      Action = [
        "ecs:CreateCapacityProvider",
        "ecs:UpdateCapacityProvider"
      ]
      Resource = "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:capacity-provider/${var.project_name}-prod-*"
    },
    # IAM PassRole（ECSタスク実行用 - prod-* ロールが対象）
    {
      Sid    = "PassRoleECSProd"
      Effect = "Allow"
      Action = [
        "iam:PassRole"
      ]
      Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-prod-*-ecs-*"
      Condition = {
        StringEquals = {
          "iam:PassedToService": [
            "ecs-tasks.amazonaws.com"
          ]
        }
      }
    },
    # ECR リポジトリ管理（削除、ポリシー削除を意図的に除外）
    {
      Sid    = "ECRRepoManagementProd"
      Effect = "Allow"
      Action = [
        "ecr:CreateRepository",
        "ecr:PutRepositoryPolicy",
        "ecr:SetRepositoryPolicy",
        "ecr:PutLifecyclePolicy",
        "ecr:PutImageTagMutability",
        "ecr:PutImageScanningConfiguration",
        "ecr:TagResource",
        "ecr:UntagResource"
      ]
      Resource = "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-prod-*"
    },
    # ECR イメージ管理（BatchDeleteImageを意図的に除外）
    {
      Sid    = "ECRImageManagementProd"
      Effect = "Allow"
      Action = [
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ]
      Resource = "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-prod-*"
    },
    # CloudWatch Logs（ECSタスクログ用 - ロググループ削除を意図的に除外）
    {
      Sid    = "ECSLogsManagementProd"
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = [
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-prod-*",
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-prod-*:*"
      ]
    }
  ]
  
  # ===================================
  # Local環境専用ステートメント
  # ===================================
  ecs_ecr_local_management_statements = local.ecs_ecr_dev_management_statements

  # ===================================
  # 環境別ポリシーステートメントのマッピング
  # ===================================
  policy_statements_ecs_ecr = {
    local = concat(
      local.ecs_ecr_common_statements,
      local.ecs_ecr_local_management_statements
    ),
    dev = concat(
      local.ecs_ecr_common_statements,
      local.ecs_ecr_dev_management_statements
    ),
    prod = concat(
      local.ecs_ecr_common_statements,
      local.ecs_ecr_prod_management_statements
    ),
    # デフォルト（フォールバック）
    default = concat(
      local.ecs_ecr_common_statements,
      local.ecs_ecr_dev_management_statements
    )
  }
}

# ===================================
# デバッグ用出力
# ===================================

output "ecs_ecr_policy_statement_counts" {
  description = "各環境のECS/ECRポリシーステートメント数"
  value = {
    for env, statements in local.policy_statements_ecs_ecr :
    env => length(statements)
  }
}

output "ecs_ecr_policy_summary" {
  description = "各環境のECS/ECRポリシー概要"
  value = {
    local   = "Local環境用 - ${var.project_name}-dev-*と同等のフル管理権限"
    dev     = "開発環境用 - ${var.project_name}-dev-* リソースへのフル管理権限（削除可）"
    prod    = "本番環境用 - ${var.project_name}-prod-* リソースへの作成・変更権限のみ（削除不可）"
    default = "デフォルト（開発環境と同等）"
  }
}