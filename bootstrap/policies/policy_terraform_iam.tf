# ===================================
# IAM関連ポリシー定義
# ===================================

locals {
  policy_statements_iam = [
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
    }
  ]

}