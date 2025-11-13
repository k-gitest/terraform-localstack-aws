# ===================================
# S3関連ポリシー定義
# ===================================

locals {
  policy_statements_s3 = [
    # 読み取り専用操作
    {
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetObjectAttributes",
        "s3:GetBucketLocation",
        "s3:GetBucketVersioning",
        "s3:GetBucketPolicy",
        "s3:GetBucketAcl",
        "s3:GetBucketCORS",
        "s3:GetBucketWebsite",
        "s3:GetLifecycleConfiguration",
        "s3:GetReplicationConfiguration",
        "s3:GetEncryptionConfiguration",
        "s3:ListBucket",
        "s3:ListBucketVersions",
        "s3:ListBucketMultipartUploads"
      ]
      Resource = [
        "arn:aws:s3:::${var.project_name}-*",
        "arn:aws:s3:::${var.project_name}-*/*"
      ]
    },
    
    # 書き込み操作（バケット管理）
    {
      Effect = "Allow"
      Action = [
        # バケット作成・削除
        "s3:CreateBucket",
        "s3:DeleteBucket", # prod_restrictionsでDenyされる
        
        # バケット設定
        "s3:PutBucketVersioning",
        "s3:PutBucketAcl",
        "s3:PutBucketPolicy",
        "s3:DeleteBucketPolicy", # prod_restrictionsでDenyされる
        "s3:PutBucketCORS",
        "s3:PutBucketWebsite",
        "s3:DeleteBucketWebsite",
        "s3:PutLifecycleConfiguration",
        "s3:PutReplicationConfiguration",
        "s3:PutEncryptionConfiguration",
        "s3:PutBucketPublicAccessBlock",
        "s3:PutBucketOwnershipControls",
        
        # バケット通知設定
        "s3:PutBucketNotification",
        "s3:GetBucketNotification",
        
        # タグ管理
        "s3:PutBucketTagging",
        "s3:GetBucketTagging"
      ]
      Resource = "arn:aws:s3:::${var.project_name}-*"
    },
    
    # オブジェクト操作
    {
      Effect = "Allow"
      Action = [
        # オブジェクト書き込み
        "s3:PutObject",
        "s3:PutObjectAcl",
        
        # オブジェクト削除（prod_restrictionsでDenyされる）
        "s3:DeleteObject",
        "s3:DeleteObjectVersion",
        
        # マルチパートアップロード
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts"
      ]
      Resource = "arn:aws:s3:::${var.project_name}-*/*"
    }
  ]
}