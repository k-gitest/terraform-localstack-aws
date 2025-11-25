# ===================================
# AWS Certificate Manager (ACM) 関連
# ===================================

locals {
  policy_statements_acm = [
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
    }
  ]
}