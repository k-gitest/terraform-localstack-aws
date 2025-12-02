# ===================================
# S3関連ポリシー定義
# ===================================

locals {
  # ===================================
  # 開発環境専用ステートメント（フル権限）
  # ===================================
  s3_dev_statements = [
    {
      Sid    = "S3ReadAccessDev"
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetObjectAttributes",
        "s3:GetBucket*",
        "s3:ListBucket*"
      ]
      Resource = [
        "arn:aws:s3:::${var.project_name}-dev-*",      # dev環境のみ
        "arn:aws:s3:::${var.project_name}-dev-*/*"
      ]
    },
    {
      Sid    = "S3ObjectWriteDev"
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts"
      ]
      Resource = "arn:aws:s3:::${var.project_name}-dev-*/*"
    },
    {
      Sid    = "S3BucketManagementDev"
      Effect = "Allow"
      Action = [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:PutBucket*",
        "s3:DeleteBucketPolicy",
        "s3:DeleteBucketWebsite"
      ]
      Resource = "arn:aws:s3:::${var.project_name}-dev-*"
    },
    {
      Sid    = "S3ObjectDeleteDev"
      Effect = "Allow"
      Action = [
        "s3:DeleteObject",
        "s3:DeleteObjectVersion"
      ]
      Resource = "arn:aws:s3:::${var.project_name}-dev-*/*"
    }
  ]

  # ===================================
  # 本番環境専用ステートメント（セキュリティ強化版）
  # ===================================
  s3_prod_statements = [
    {
      Sid    = "S3ReadAccessProd"
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetObjectAttributes",
        "s3:GetBucket*",
        "s3:ListBucket*"
      ]
      Resource = [
        "arn:aws:s3:::${var.project_name}-prod-*",     # prod環境のみ
        "arn:aws:s3:::${var.project_name}-prod-*/*"
      ]
    },
    {
      Sid    = "S3ObjectWriteProd"
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts"
      ]
      Resource = "arn:aws:s3:::${var.project_name}-prod-*/*"
    },
    {
      Sid    = "S3BucketManagementProd"
      Effect = "Allow"
      Action = [
        # 作成は許可（初回デプロイ用）
        "s3:CreateBucket",
        
        # 設定変更は許可（バージョニング、暗号化など）
        "s3:PutBucket*"
        
        # 削除系は完全に除外
        # - s3:DeleteBucket
        # - s3:DeleteBucketPolicy
        # - s3:DeleteBucketWebsite
      ]
      Resource = "arn:aws:s3:::${var.project_name}-prod-*"
    }
    
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # 重要: オブジェクト削除は完全に除外
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # 本番環境のオブジェクト削除は不要
    # 理由:
    # 1. 本番データは永続的
    # 2. 削除が必要な場合は管理者が手動実行すべき
    # 3. ライフサイクルルールで自動削除対応
    # 4. prod_restrictions.tf でも Deny されている（二重保護）
    #
    # 以前の S3ObjectDeleteLimited は削除:
    # - 一時ファイルもライフサイクルで自動削除
    # - Terraformが削除する必要はない
  ]

  # ===================================
  # Local環境専用ステートメント（LocalStack用）
  # ===================================
  s3_local_statements = [
    {
      Sid    = "S3ReadAccessLocal"
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetObjectAttributes",
        "s3:GetBucket*",
        "s3:ListBucket*"
      ]
      Resource = [
        "arn:aws:s3:::${var.project_name}-local-*",    # local環境のみ
        "arn:aws:s3:::${var.project_name}-local-*/*"
      ]
    },
    {
      Sid    = "S3ObjectWriteLocal"
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts"
      ]
      Resource = "arn:aws:s3:::${var.project_name}-local-*/*"
    },
    {
      Sid    = "S3BucketManagementLocal"
      Effect = "Allow"
      Action = [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:PutBucket*",
        "s3:DeleteBucketPolicy",
        "s3:DeleteBucketWebsite"
      ]
      Resource = "arn:aws:s3:::${var.project_name}-local-*"
    },
    {
      Sid    = "S3ObjectDeleteLocal"
      Effect = "Allow"
      Action = [
        "s3:DeleteObject",
        "s3:DeleteObjectVersion"
      ]
      Resource = "arn:aws:s3:::${var.project_name}-local-*/*"
    }
  ]

  # ===================================
  # 環境別ポリシーステートメントのマッピング
  # ===================================
  policy_statements_s3 = {
    # Local環境（LocalStack用）
    local = local.s3_local_statements

    # 開発環境
    dev = local.s3_dev_statements

    # 本番環境
    prod = local.s3_prod_statements

    # デフォルト（新しい環境追加時のフォールバック）
    default = local.s3_dev_statements
  }
}

# ===================================
# デバッグ用出力
# ===================================
output "s3_policy_statement_counts" {
  description = "各環境のS3ポリシーステートメント数"
  value = {
    for env, statements in local.policy_statements_s3 :
    env => length(statements)
  }
}

output "s3_policy_summary" {
  description = "各環境のS3ポリシー概要"
  value = {
    local = "LocalStack用 - ${var.project_name}-local-* のみアクセス可能（削除可）"
    dev   = "開発環境用 - ${var.project_name}-dev-* のみアクセス可能（削除可）"
    prod  = "本番環境用 - ${var.project_name}-prod-* のみアクセス可能（削除不可）"
  }
}

# ===================================
# セキュリティ設計の説明
# ===================================
# 
# 【環境分離の重要性】
# 
# ❌ 改善前（共通ステートメント使用）:
#   - dev環境のロール → prod環境のS3も読める
#   - prod環境のロール → dev環境のS3も読める
#   - セキュリティリスク: 環境間のデータ漏洩の可能性
# 
# ✅ 改善後（環境別Resource）:
#   - dev環境のロール → dev環境のS3のみ
#   - prod環境のロール → prod環境のS3のみ
#   - 最小権限の原則: 必要なリソースのみアクセス可能
# 
# 【本番環境の削除ポリシー】
# 
# - バケット削除: 完全に除外（初回作成後は不要）
# - オブジェクト削除: 完全に除外（ライフサイクルで対応）
# - 一時ファイル削除: S3ライフサイクルルールで自動削除
# 
# 【コードの重複について】
# 
# - 各環境で似たコードが重複しているが、これは意図的
# - 環境ごとのResource ARNを明確に分離することが最優先
# - セキュリティ > DRY原則