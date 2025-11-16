# ===================================
# ECS関連ポリシー定義
# ===================================

locals {
  policy_statements_lambda = [
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
    }
  ]
}