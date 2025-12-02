# ===================================
# CloudFront関連ポリシー定義（環境分離・セキュリティ強化版）
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
  cloudfront_common_statements = [
    {
      Sid    = "CloudFrontReadAccess"
      Effect = "Allow"
      Action = [
        # List系、Get系、Describe系は全て読み取りとして全体を許可
        "cloudfront:GetDistribution",
        "cloudfront:GetDistributionConfig",
        "cloudfront:ListDistributions",
        "cloudfront:ListDistributionsByWebACLId",
        "cloudfront:GetCachePolicy",
        "cloudfront:GetCachePolicyConfig",
        "cloudfront:ListCachePolicies",
        "cloudfront:GetOriginRequestPolicy",
        "cloudfront:GetOriginRequestPolicyConfig",
        "cloudfront:ListOriginRequestPolicies",
        "cloudfront:GetResponseHeadersPolicy",
        "cloudfront:GetResponseHeadersPolicyConfig",
        "cloudfront:ListResponseHeadersPolicies",
        "cloudfront:GetOriginAccessControl",
        "cloudfront:GetOriginAccessControlConfig",
        "cloudfront:ListOriginAccessControls",
        "cloudfront:GetInvalidation",
        "cloudfront:ListInvalidations",
        "cloudfront:DescribeFunction",
        "cloudfront:ListFunctions",
        "cloudfront:ListTagsForResource"
      ]
      Resource = "*" 
    }
  ]
  
  # ===================================
  # 開発環境専用ステートメント（ディストリビューションフル管理）
  # ===================================
  cloudfront_dev_management_statements = [
    # ディストリビューション作成（タグ付与を強制）
    {
      Sid    = "CreateDistributionDev"
      Effect = "Allow"
      Action = ["cloudfront:CreateDistribution"]
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

    # ディストリビューション更新・削除（リソースタグでフィルタ）
    {
      Sid    = "ManageDistributionDev"
      Effect = "Allow"
      Action = [
        "cloudfront:UpdateDistribution",
        "cloudfront:DeleteDistribution", # 開発環境は削除可能
        "cloudfront:TagResource",
        "cloudfront:UntagResource"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project": var.project_name
          "aws:ResourceTag/Environment": "dev"
        }
      }
    },
    
    # キャッシュクリア（Invalidation）権限付与
    {
      Sid    = "CreateInvalidationDev"
      Effect = "Allow"
      Action = ["cloudfront:CreateInvalidation"]
      # InvalidationのResourceはディストリビューションARN
      Resource = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project": var.project_name
          "aws:ResourceTag/Environment": "dev"
        }
      }
    },

    # ポリシーリソース管理 (OAC/Function/RequestPolicy/HeaderPolicy)
    # これらは共通のリソースARNパターンを持つため、環境別の ARN 制限はできないが、
    # 実際にはディストリビューションに紐づくため、ディストリビューションが環境別タグで守られていれば許容
    {
      Sid    = "PolicyResourcesManagementDev"
      Effect = "Allow"
      Action = [
        "cloudfront:CreateCachePolicy",
        "cloudfront:UpdateCachePolicy",
        "cloudfront:DeleteCachePolicy",
        "cloudfront:CreateOriginRequestPolicy",
        "cloudfront:UpdateOriginRequestPolicy",
        "cloudfront:DeleteOriginRequestPolicy",
        "cloudfront:CreateResponseHeadersPolicy",
        "cloudfront:UpdateResponseHeadersPolicy",
        "cloudfront:DeleteResponseHeadersPolicy",
        "cloudfront:CreateOriginAccessControl",
        "cloudfront:UpdateOriginAccessControl",
        "cloudfront:DeleteOriginAccessControl",
        "cloudfront:CreateFunction",
        "cloudfront:UpdateFunction",
        "cloudfront:DeleteFunction",
        "cloudfront:PublishFunction",
        "cloudfront:TestFunction"
      ]
      Resource = [
        "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:cache-policy/*",
        "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:origin-request-policy/*",
        "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:response-headers-policy/*",
        "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:origin-access-control/*",
        "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:function/*"
      ]
    }
  ]
  
  # ===================================
  # 本番環境専用ステートメント（ディストリビューション作成・更新のみ）
  # ===================================
  cloudfront_prod_management_statements = [
    # ディストリビューション作成（タグ付与を強制）
    {
      Sid    = "CreateDistributionProd"
      Effect = "Allow"
      Action = ["cloudfront:CreateDistribution"]
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

    # ディストリビューション更新（削除除外、リソースタグでフィルタ）
    {
      Sid    = "ManageDistributionProd"
      Effect = "Allow"
      Action = [
        "cloudfront:UpdateDistribution",
        # "cloudfront:DeleteDistribution", # ❌ 除外
        "cloudfront:TagResource",
        "cloudfront:UntagResource"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project": var.project_name
          "aws:ResourceTag/Environment": "prod"
        }
      }
    },
    
    # キャッシュクリア（Invalidation）権限付与
    {
      Sid    = "CreateInvalidationProd"
      Effect = "Allow"
      Action = ["cloudfront:CreateInvalidation"]
      # InvalidationのResourceはディストリビューションARN
      Resource = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project": var.project_name
          "aws:ResourceTag/Environment": "prod"
        }
      }
    },

    # ポリシーリソース管理 (OAC/Function/RequestPolicy/HeaderPolicy)
    # 開発環境と同じフル管理権限を与える
    {
      Sid    = "PolicyResourcesManagementProd"
      Effect = "Allow"
      Action = local.cloudfront_dev_management_statements[3].Action
      Resource = local.cloudfront_dev_management_statements[3].Resource
    }
  ]
  
  # ===================================
  # Local環境専用ステートメント
  # ===================================
  cloudfront_local_management_statements = local.cloudfront_dev_management_statements

  # ===================================
  # 環境別ポリシーステートメントのマッピング
  # ===================================
  policy_statements_cloudfront = {
    local = concat(
      local.cloudfront_common_statements,
      local.cloudfront_local_management_statements
    ),
    dev = concat(
      local.cloudfront_common_statements,
      local.cloudfront_dev_management_statements
    ),
    prod = concat(
      local.cloudfront_common_statements,
      local.cloudfront_prod_management_statements
    ),
    # デフォルト（フォールバック）
    default = concat(
      local.cloudfront_common_statements,
      local.cloudfront_dev_management_statements
    )
  }
}

# ===================================
# デバッグ用出力
# ===================================

output "cloudfront_policy_statement_counts" {
  description = "各環境のCloudFrontポリシーステートメント数"
  value = {
    for env, statements in local.policy_statements_cloudfront :
    env => length(statements)
  }
}

output "cloudfront_policy_summary" {
  description = "各環境のCloudFrontポリシー概要"
  value = {
    local   = "Local環境用 - ${var.project_name}-dev/localタグのリソースへのフル管理権限"
    dev     = "開発環境用 - ${var.project_name}-devタグのリソースへのフル管理権限（削除可）"
    prod    = "本番環境用 - ${var.project_name}-prodタグのリソースへの作成・更新権限のみ（ディストリビューション削除不可）"
    default = "デフォルト（開発環境と同等）"
  }
}