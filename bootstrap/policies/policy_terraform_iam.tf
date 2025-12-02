# ===================================
# IAM関連ポリシー定義
# ===================================

locals {
  # ===================================
  # 共通ステートメント（読み取り専用）
  # ===================================
  iam_common_statements = [
    {
      Sid      = "IAMListAccess"
      Effect   = "Allow"
      Action   = [
        "iam:List*",
        "iam:GetContextKeysForCustomPolicy",
        "iam:GetContextKeysForPrincipalPolicy"
      ]
      Resource = "*"
    }
  ]
  
  # ===================================
  # 開発環境専用ステートメント（dev-* リソースへのフル管理）
  # ===================================
  iam_dev_management_statements = [
    # 環境別読み取り
    {
      Sid    = "IAMEnvReadAccessDev"
      Effect = "Allow"
      Action = [
        "iam:GetRole",
        "iam:GetPolicy",
        "iam:GetRolePolicy",
        "iam:GetInstanceProfile"
      ]
      Resource = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-dev-*",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project_name}-dev-*",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.project_name}-dev-*"
      ]
    },
    
    # フル管理（削除含む）
    {
      Sid    = "RolePolicyManagementDev"
      Effect = "Allow"
      Action = [
        "iam:CreateRole",
        "iam:DeleteRole",          # 開発環境は削除可能
        "iam:UpdateRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",    # 開発環境は削除可能
        "iam:CreatePolicy",
        "iam:DeletePolicy",        # 開発環境は削除可能
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile", # 開発環境は削除可能
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:TagPolicy",
        "iam:UntagPolicy"
      ]
      Resource = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-dev-*",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project_name}-dev-*",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.project_name}-dev-*"
      ]
    },
    
    # PassRole制限
    {
      Sid      = "PassRoleDev"
      Effect   = "Allow"
      Action   = ["iam:PassRole"]
      Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-dev-*"
      Condition = {
        StringEquals = {
          "iam:PassedToService": [
            "lambda.amazonaws.com",
            "ecs-tasks.amazonaws.com",
            "ec2.amazonaws.com",
            "rds.amazonaws.com",
            "amplify.amazonaws.com"
          ]
        }
      }
    }
  ]
  
  # ===================================
  # 本番環境専用ステートメント（prod-* リソースへの作成・変更のみ）
  # ===================================
  iam_prod_management_statements = [
    # 環境別読み取り
    {
      Sid    = "IAMEnvReadAccessProd"
      Effect = "Allow"
      Action = [
        "iam:GetRole",
        "iam:GetPolicy",
        "iam:GetRolePolicy",
        "iam:GetInstanceProfile"
      ]
      Resource = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-prod-*",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project_name}-prod-*",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.project_name}-prod-*"
      ]
    },

    # 作成・変更のみ（削除系は意図的に除外）
    {
      Sid    = "RolePolicyManagementProd"
      Effect = "Allow"
      Action = [
        "iam:CreateRole",
        # "iam:DeleteRole" ❌ 除外
        "iam:UpdateRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        # "iam:DeleteRolePolicy" ❌ 除外
        "iam:CreatePolicy",
        # "iam:DeletePolicy" ❌ 除外
        "iam:CreateInstanceProfile",
        # "iam:DeleteInstanceProfile" ❌ 除外
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:TagPolicy",
        "iam:UntagPolicy"
      ]
      Resource = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-prod-*",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project_name}-prod-*",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.project_name}-prod-*"
      ]
    },
    
    # PassRole制限
    {
      Sid      = "PassRoleProd"
      Effect   = "Allow"
      Action   = ["iam:PassRole"]
      Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-prod-*"
      Condition = {
        StringEquals = {
          "iam:PassedToService": [
            "lambda.amazonaws.com",
            "ecs-tasks.amazonaws.com",
            "ec2.amazonaws.com",
            "rds.amazonaws.com",
            "amplify.amazonaws.com"
          ]
        }
      }
    }
    
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # ⚠️ Denyは含めない
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # 理由:
    # 1. policy_prod_restrictions.tf で一元管理
    # 2. Allow ポリシーにDenyを混在させない（単一責任の原則）
    # 3. コードの可読性と保守性の向上
  ]
  
  # ===================================
  # Local環境専用ステートメント
  # ===================================
  iam_local_management_statements = local.iam_dev_management_statements 

  # ===================================
  # 環境別ポリシーステートメントのマッピング
  # ===================================
  policy_statements_iam = {
    local = concat(
      local.iam_common_statements,
      local.iam_local_management_statements
    ),
    dev = concat(
      local.iam_common_statements,
      local.iam_dev_management_statements
    ),
    prod = concat(
      local.iam_common_statements,
      local.iam_prod_management_statements
    ),
    default = concat(
      local.iam_common_statements,
      local.iam_dev_management_statements
    )
  }
}

# ===================================
# デバッグ用出力
# ===================================

output "iam_policy_statement_counts" {
  description = "各環境のIAMポリシーステートメント数"
  value = {
    for env, statements in local.policy_statements_iam :
    env => length(statements)
  }
}

output "iam_policy_summary" {
  description = "各環境のIAMポリシー概要"
  value = {
    local   = "Local環境用 - ${var.project_name}-dev-*と同等のフル管理権限"
    dev     = "開発環境用 - ${var.project_name}-dev-* リソースへのフル管理権限"
    prod    = "本番環境用 - ${var.project_name}-prod-* リソースへの作成・変更権限のみ（削除不可）"
    default = "デフォルト（開発環境と同等）"
  }
}

# ===================================
# セキュリティ設計の説明
# ===================================
#
# 【設計思想】
#
# 1. Allow ポリシー（このファイル）
#    - 環境ごとに必要な権限を定義
#    - 本番環境では削除系アクションを含めない
#    - 「何ができるか」を定義
#
# 2. Deny ポリシー（policy_prod_restrictions.tf）
#    - 本番環境の破壊的操作を明示的に拒否
#    - すべてのサービスのDenyを一箇所で管理
#    - 「何ができないか」を定義
#
# 【なぜ分離するのか】
#
# ✅ 単一責任の原則
#    - Allowポリシー: 権限の付与
#    - Denyポリシー: 権限の制限
#
# ✅ 保守性の向上
#    - Deny ポリシーを一箇所で管理
#    - 全サービスの制限を統一的に確認可能
#
# ✅ コードレビューの容易性
#    - Allow変更とDeny変更を分けて議論
#    - 変更の影響範囲が明確
#
# 【二重保護の仕組み】
#
# 第1層: Allowに含めない
#   → 本番環境のステートメントに削除系アクションがない
#
# 第2層: Denyで明示的に拒否（policy_prod_restrictions.tf）
#   → 万が一Allowに追加されても、Denyが優先される
#
# この二重保護により、ヒューマンエラーから本番環境を守ります。