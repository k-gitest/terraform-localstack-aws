# ポリシー設定のマップ
locals {
  policy_configs = {
    "private" = {
      create_policy = false
      policy_document = null
      block_public_access = true
    }
    
    "public-read" = {
      create_policy = true
      policy_document = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid       = "PublicReadGetObject"
            Effect    = "Allow"
            Principal = "*"
            Action    = "s3:GetObject"
            Resource  = "${aws_s3_bucket.this.arn}/*"
          }
        ]
      }
      block_public_access = false
    }
    
    "cloudfront-oac" = {
      create_policy = true
      policy_document = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "AllowCloudFrontServicePrincipal"
            Effect = "Allow"
            Principal = {
              Service = "cloudfront.amazonaws.com"
            }
            Action   = "s3:GetObject"
            Resource = "${aws_s3_bucket.this.arn}/*"
            Condition = {
              StringEquals = {
                "AWS:SourceArn" = var.cloudfront_distribution_arn
              }
            }
          }
        ]
      }
      block_public_access = true
    }
  }
  
  # 現在の設定を取得
  current_config = local.policy_configs[var.policy_type]
}