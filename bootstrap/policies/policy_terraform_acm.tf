# ===================================
# AWS Certificate Manager (ACM) 関連ポリシー定義（環境分離・セキュリティ強化版）
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
  acm_common_statements = [
    {
      Sid    = "ACMReadAccess"
      Effect = "Allow"
      Action = [
        "acm:DescribeCertificate",
        "acm:GetCertificate",
        "acm:ListCertificates",
        "acm:ListTagsForCertificate"
      ]
      Resource = "*"
    }
  ]
  
  # ===================================
  # 開発環境専用ステートメント（devタグを持つリソースへのフル管理）
  # ===================================
  acm_dev_management_statements = [
    # 証明書リクエスト（devタグ必須）
    {
      Sid    = "RequestCertificateDev"
      Effect = "Allow"
      Action = ["acm:RequestCertificate"]
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
    
    # 証明書インポート（devタグ必須）
    {
      Sid    = "ImportCertificateDev"
      Effect = "Allow"
      Action = ["acm:ImportCertificate"]
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

    # 証明書管理（フル管理 - devタグでフィルタ）
    {
      Sid    = "ManageCertificateDev"
      Effect = "Allow"
      Action = [
        "acm:DeleteCertificate", # 開発環境は削除可能
        "acm:RenewCertificate",
        "acm:ResendValidationEmail",
        "acm:AddTagsToCertificate",
        "acm:RemoveTagsFromCertificate"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project": var.project_name
          "aws:ResourceTag/Environment": "dev"
        }
      }
    }
  ]
  
  # ===================================
  # 本番環境専用ステートメント（prodタグを持つリソースへの作成・更新のみ）
  # ===================================
  acm_prod_management_statements = [
    # 証明書リクエスト（prodタグ必須）
    {
      Sid    = "RequestCertificateProd"
      Effect = "Allow"
      Action = ["acm:RequestCertificate"]
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
    
    # 証明書インポート（prodタグ必須）
    {
      Sid    = "ImportCertificateProd"
      Effect = "Allow"
      Action = ["acm:ImportCertificate"]
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

    # 証明書管理（削除除外 - prodタグでフィルタ）
    {
      Sid    = "ManageCertificateProd"
      Effect = "Allow"
      Action = [
        # "acm:DeleteCertificate", # ❌ 除外
        "acm:RenewCertificate",
        "acm:ResendValidationEmail",
        "acm:AddTagsToCertificate",
        "acm:RemoveTagsFromCertificate"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project": var.project_name
          "aws:ResourceTag/Environment": "prod"
        }
      }
    }
  ]
  
  # ===================================
  # Local環境専用ステートメント
  # ===================================
  acm_local_management_statements = local.acm_dev_management_statements

  # ===================================
  # 環境別ポリシーステートメントのマッピング
  # ===================================
  policy_statements_acm = {
    local = concat(
      local.acm_common_statements,
      local.acm_local_management_statements
    ),
    dev = concat(
      local.acm_common_statements,
      local.acm_dev_management_statements
    ),
    prod = concat(
      local.acm_common_statements,
      local.acm_prod_management_statements
    ),
    # デフォルト（フォールバック）
    default = concat(
      local.acm_common_statements,
      local.acm_dev_management_statements
    )
  }
}

# ===================================
# デバッグ用出力
# ===================================

output "acm_policy_statement_counts" {
  description = "各環境のACMポリシーのステートメント数"
  value = {
    for env, statements in local.policy_statements_acm :
    env => length(statements)
  }
}

output "acm_policy_summary" {
  description = "各環境のACMポリシー概要"
  value = {
    local   = "Local環境用 - devタグを持つ証明書へのフル管理権限"
    dev     = "開発環境用 - devタグを持つ証明書へのフル管理権限（削除可）"
    prod    = "本番環境用 - prodタグを持つ証明書への作成・更新権限のみ（証明書削除不可）"
    default = "デフォルト（開発環境と同等）"
  }
}