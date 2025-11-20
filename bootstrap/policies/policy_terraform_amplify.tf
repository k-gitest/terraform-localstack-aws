# ===================================
# Amplify関連
# ===================================

locals {
  policy_statements_amplify = [
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
    }
  ]
}