# ===================================
# Amplify関連ポリシー定義（環境分離・セキュリティ強化版）
# ===================================

locals {
  # 必須とするリクエストタグ
  required_request_tags = {
    "aws:RequestTag/Project": var.project_name,
    "aws:RequestTag/ManagedBy": "terraform"
  }

  # ===================================
  # 共通ステートメント（読み取り専用）
  # ===================================
  amplify_common_statements = [
    {
      Sid    = "AmplifyReadAccess"
      Effect = "Allow"
      Action = [
        # List系、Get系は全て読み取りとして全体を許可
        "amplify:GetApp",
        "amplify:ListApps",
        "amplify:GetBranch",
        "amplify:ListBranches",
        "amplify:GetJob",
        "amplify:ListJobs",
        "amplify:GetDomainAssociation",
        "amplify:ListDomainAssociations",
        "amplify:GetWebhook",
        "amplify:ListWebhooks",
        "amplify:GetBackendEnvironment",
        "amplify:ListBackendEnvironments",
        "amplify:GetArtifactUrl",
        "amplify:ListArtifacts",
        "amplify:ListTagsForResource"
      ]
      Resource = "*" 
    }
  ]
  
  # ===================================
  # 開発環境専用ステートメント（dev-* リソースへのフル管理）
  # ===================================
  amplify_dev_management_statements = [
    # アプリ作成（タグ付与を強制）
    {
      Sid    = "CreateAppDev"
      Effect = "Allow"
      Action = ["amplify:CreateApp"]
      Resource = "*"
      Condition = merge(
        local.required_request_tags,
        {
          StringEquals = {
            "aws:RequestTag/Environment": "dev"
          }
        }
      )
    },

    # アプリ更新・削除（フル管理）
    {
      Sid    = "ManageAppDev"
      Effect = "Allow"
      Action = [
        "amplify:UpdateApp",
        "amplify:DeleteApp", # 開発環境は削除可能
        "amplify:TagResource",
        "amplify:UntagResource"
      ]
      Resource = "arn:aws:amplify:*:${data.aws_caller_identity.current.account_id}:apps/${var.project_name}-dev-*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project": var.project_name
          "aws:ResourceTag/Environment": "dev"
        }
      }
    },
    
    # ブランチ・ジョブ管理（フル管理）
    {
      Sid    = "ManageBranchJobDev"
      Effect = "Allow"
      Action = [
        "amplify:CreateBranch",
        "amplify:UpdateBranch",
        "amplify:DeleteBranch", # 開発環境は削除可能
        "amplify:StartJob",
        "amplify:StopJob",
        "amplify:StartDeployment",
        "amplify:CreateDeployment"
      ]
      Resource = "arn:aws:amplify:*:${data.aws_caller_identity.current.account_id}:apps/${var.project_name}-dev-*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project": var.project_name
          "aws:ResourceTag/Environment": "dev"
        }
      }
    },

    # ドメイン管理
    {
      Sid    = "ManageDomainDev"
      Effect = "Allow"
      Action = [
        "amplify:CreateDomainAssociation",
        "amplify:UpdateDomainAssociation",
        "amplify:DeleteDomainAssociation"
      ]
      Resource = "arn:aws:amplify:*:${data.aws_caller_identity.current.account_id}:apps/${var.project_name}-dev-*/domains/*"
    },

    # Webhook管理
    {
      Sid    = "ManageWebhookDev"
      Effect = "Allow"
      Action = [
        "amplify:CreateWebhook",
        "amplify:UpdateWebhook",
        "amplify:DeleteWebhook"
      ]
      Resource = "arn:aws:amplify:*:${data.aws_caller_identity.current.account_id}:apps/${var.project_name}-dev-*/webhooks/*"
    },

    # バックエンド環境管理（フル管理）
    {
      Sid    = "ManageBackendEnvDev"
      Effect = "Allow"
      Action = [
        "amplify:CreateBackendEnvironment",
        "amplify:UpdateBackendEnvironment",
        "amplify:DeleteBackendEnvironment" # 開発環境は削除可能
      ]
      Resource = "arn:aws:amplify:*:${data.aws_caller_identity.current.account_id}:apps/${var.project_name}-dev-*/backendenvironments/*"
    },
    
    # IAM PassRole（Amplifyサービスロール用）
    {
      Sid    = "PassRoleDev"
      Effect = "Allow"
      Action = ["iam:PassRole"]
      Resource = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-dev-*-amplify-role"
      ]
      Condition = {
        StringEquals = {
          "iam:PassedToService": "amplify.amazonaws.com"
        }
      }
    }
  ]
  
  # ===================================
  # 本番環境専用ステートメント（prod-* リソースへの作成・変更のみ）
  # ===================================
  amplify_prod_management_statements = [
    # アプリ作成（タグ付与を強制）
    {
      Sid    = "CreateAppProd"
      Effect = "Allow"
      Action = ["amplify:CreateApp"]
      Resource = "*"
      Condition = merge(
        local.required_request_tags,
        {
          StringEquals = {
            "aws:RequestTag/Environment": "prod"
          }
        }
      )
    },

    # アプリ更新（削除除外）
    {
      Sid    = "ManageAppProd"
      Effect = "Allow"
      Action = [
        "amplify:UpdateApp",
        # "amplify:DeleteApp", # ❌ 除外
        "amplify:TagResource",
        "amplify:UntagResource"
      ]
      Resource = "arn:aws:amplify:*:${data.aws_caller_identity.current.account_id}:apps/${var.project_name}-prod-*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project": var.project_name
          "aws:ResourceTag/Environment": "prod"
        }
      }
    },
    
    # ブランチ・ジョブ管理（削除除外）
    {
      Sid    = "ManageBranchJobProd"
      Effect = "Allow"
      Action = [
        "amplify:CreateBranch",
        "amplify:UpdateBranch",
        # "amplify:DeleteBranch", # ❌ 除外
        "amplify:StartJob",
        "amplify:StopJob",
        "amplify:StartDeployment",
        "amplify:CreateDeployment"
      ]
      Resource = "arn:aws:amplify:*:${data.aws_caller_identity.current.account_id}:apps/${var.project_name}-prod-*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project": var.project_name
          "aws:ResourceTag/Environment": "prod"
        }
      }
    },

    # ドメイン管理
    {
      Sid    = "ManageDomainProd"
      Effect = "Allow"
      Action = [
        "amplify:CreateDomainAssociation",
        "amplify:UpdateDomainAssociation",
        "amplify:DeleteDomainAssociation"
      ]
      Resource = "arn:aws:amplify:*:${data.aws_caller_identity.current.account_id}:apps/${var.project_name}-prod-*/domains/*"
    },

    # Webhook管理
    {
      Sid    = "ManageWebhookProd"
      Effect = "Allow"
      Action = [
        "amplify:CreateWebhook",
        "amplify:UpdateWebhook",
        "amplify:DeleteWebhook"
      ]
      Resource = "arn:aws:amplify:*:${data.aws_caller_identity.current.account_id}:apps/${var.project_name}-prod-*/webhooks/*"
    },

    # バックエンド環境管理（削除除外）
    {
      Sid    = "ManageBackendEnvProd"
      Effect = "Allow"
      Action = [
        "amplify:CreateBackendEnvironment",
        "amplify:UpdateBackendEnvironment",
        # "amplify:DeleteBackendEnvironment" # ❌ 除外
      ]
      Resource = "arn:aws:amplify:*:${data.aws_caller_identity.current.account_id}:apps/${var.project_name}-prod-*/backendenvironments/*"
    },
    
    # IAM PassRole（Amplifyサービスロール用）
    {
      Sid    = "PassRoleProd"
      Effect = "Allow"
      Action = ["iam:PassRole"]
      Resource = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-prod-*-amplify-role"
      ]
      Condition = {
        StringEquals = {
          "iam:PassedToService": "amplify.amazonaws.com"
        }
      }
    }
  ]
  
  # ===================================
  # Local環境専用ステートメント
  # ===================================
  amplify_local_management_statements = local.amplify_dev_management_statements

  # ===================================
  # 環境別ポリシーステートメントのマッピング
  # ===================================
  policy_statements_amplify = {
    local = concat(
      local.amplify_common_statements,
      local.amplify_local_management_statements
    ),
    dev = concat(
      local.amplify_common_statements,
      local.amplify_dev_management_statements
    ),
    prod = concat(
      local.amplify_common_statements,
      local.amplify_prod_management_statements
    ),
    # デフォルト（フォールバック）
    default = concat(
      local.amplify_common_statements,
      local.amplify_dev_management_statements
    )
  }
}

# ===================================
# デバッグ用出力
# ===================================

output "amplify_policy_statement_counts" {
  description = "各環境のAmplifyポリシーステートメント数"
  value = {
    for env, statements in local.policy_statements_amplify :
    env => length(statements)
  }
}

output "amplify_policy_summary" {
  description = "各環境のAmplifyポリシー概要"
  value = {
    local   = "Local環境用 - ${var.project_name}-dev/localタグのリソースへのフル管理権限"
    dev     = "開発環境用 - ${var.project_name}-devタグのリソースへのフル管理権限（削除可）"
    prod    = "本番環境用 - ${var.project_name}-prodタグのリソースへの作成・更新権限のみ（アプリ/ブランチ/バックエンド環境の削除不可）"
    default = "デフォルト（開発環境と同等）"
  }
}