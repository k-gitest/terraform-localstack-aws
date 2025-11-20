# ===================================
# CloudFront関連
# ===================================

locals {
  policy_statements_cloudfront = [
    # 1. 読み取り専用操作
    {
      Effect = "Allow"
      Action = [
        # ディストリビューション
        "cloudfront:GetDistribution",
        "cloudfront:GetDistributionConfig",
        "cloudfront:ListDistributions",
        "cloudfront:ListDistributionsByWebACLId",
        
        # キャッシュポリシー
        "cloudfront:GetCachePolicy",
        "cloudfront:GetCachePolicyConfig",
        "cloudfront:ListCachePolicies",
        
        # オリジンリクエストポリシー
        "cloudfront:GetOriginRequestPolicy",
        "cloudfront:GetOriginRequestPolicyConfig",
        "cloudfront:ListOriginRequestPolicies",
        
        # レスポンスヘッダーポリシー
        "cloudfront:GetResponseHeadersPolicy",
        "cloudfront:GetResponseHeadersPolicyConfig",
        "cloudfront:ListResponseHeadersPolicies",
        
        # Origin Access Control (OAC)
        "cloudfront:GetOriginAccessControl",
        "cloudfront:GetOriginAccessControlConfig",
        "cloudfront:ListOriginAccessControls",
        
        # Invalidation（キャッシュクリア）
        "cloudfront:GetInvalidation",
        "cloudfront:ListInvalidations",
        
        # CloudFront Functions
        "cloudfront:DescribeFunction",
        "cloudfront:ListFunctions",
        
        # タグ
        "cloudfront:ListTagsForResource"
      ]
      Resource = "*"  # 読み取りなので全体を許可
    },

    # 2. ディストリビューション作成（タグ付与を強制）
    {
      Effect = "Allow"
      Action = [
        "cloudfront:CreateDistribution"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "aws:RequestTag/Project": var.project_name
          "aws:RequestTag/ManagedBy": "terraform"
        }
      }
    },

    # 3. ディストリビューション更新・削除（プロジェクトタグでフィルタ）
    {
      Effect = "Allow"
      Action = [
        "cloudfront:UpdateDistribution",
        "cloudfront:DeleteDistribution",  # prod_restrictionsでDenyされる
        "cloudfront:TagResource",
        "cloudfront:UntagResource"
      ]
      Resource = "*"
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project": var.project_name
        }
      }
    },

    # 4. キャッシュポリシー管理
    # frontend_deployで管理するため、ここでは除外
    # {
    #   Effect = "Allow"
    #   Action = [
    #     "cloudfront:CreateCachePolicy",
    #     "cloudfront:UpdateCachePolicy",
    #     "cloudfront:DeleteCachePolicy"
    #   ]
    #   Resource = [
    #     "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:cache-policy/*"
    #   ]
    # },

    # 5. オリジンリクエストポリシー管理
    {
      Effect = "Allow"
      Action = [
        "cloudfront:CreateOriginRequestPolicy",
        "cloudfront:UpdateOriginRequestPolicy",
        "cloudfront:DeleteOriginRequestPolicy"
      ]
      Resource = [
        "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:origin-request-policy/*"
      ]
    },

    # 6. レスポンスヘッダーポリシー管理
    {
      Effect = "Allow"
      Action = [
        "cloudfront:CreateResponseHeadersPolicy",
        "cloudfront:UpdateResponseHeadersPolicy",
        "cloudfront:DeleteResponseHeadersPolicy"
      ]
      Resource = [
        "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:response-headers-policy/*"
      ]
    },

    # 7. Origin Access Control (OAC) 管理
    {
      Effect = "Allow"
      Action = [
        "cloudfront:CreateOriginAccessControl",
        "cloudfront:UpdateOriginAccessControl",
        "cloudfront:DeleteOriginAccessControl"
      ]
      Resource = [
        "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:origin-access-control/*"
      ]
    },

    # 8. CloudFront Functions管理
    {
      Effect = "Allow"
      Action = [
        "cloudfront:CreateFunction",
        "cloudfront:UpdateFunction",
        "cloudfront:DeleteFunction",
        "cloudfront:PublishFunction",
        "cloudfront:TestFunction"
      ]
      Resource = [
        "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:function/*"
      ]
    }
  ]
}