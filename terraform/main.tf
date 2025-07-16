# s3のモジュール呼び出し
// --- フロントエンドアプリケーション用S3バケット ---
module "frontend_app_s3" {
  source = "./modules/s3"
  bucket_name               = "my-app-frontend-bucket-prod"
  tags = {
    Environment = "Production"
    Project     = "FrontendApp"
  }
  enable_website_hosting    = true
  index_document_suffix     = "index.html"
  error_document_key        = "index.html"
  enable_public_read_policy = true
  block_public_acls         = true
  block_public_policy       = false
  ignore_public_acls        = true
  restrict_public_buckets   = false
  enable_versioning         = true
  enable_encryption         = true
}

# ユーザーコンテンツ用バケットの作成
# バケット定義
locals {
  user_content_buckets = {
    "profile_pictures" = {
      bucket_name = "my-app-profile-pictures-bucket-prod"
      tags        = { ContentType = "ProfilePictures" }
      versioning  = true
      encryption  = true
      # ... その他の共通設定 ...
    },
    "user_documents" = {
      bucket_name = "my-app-user-documents-bucket-prod"
      tags        = { ContentType = "Documents" }
      versioning  = true
      encryption  = true
      # ...
    },
    "temp_uploads" = {
      bucket_name = "my-app-temp-uploads-bucket-prod"
      tags        = { ContentType = "TempFiles" }
      versioning  = false
      encryption  = true
      # ... ライフサイクルポリシーなどのカスタム設定もマップに含める ...
    },
  }
}

// 2. for_each を使ってモジュールを呼び出す
module "user_content_s3_buckets" {
  for_each = local.user_content_buckets
  source   = "./modules/s3"

  bucket_name               = each.value.bucket_name
  tags                      = merge({ Environment = "Production", Project = "UserContent" }, each.value.tags)

  enable_website_hosting    = false
  enable_public_read_policy = false
  block_public_acls         = true
  block_public_policy       = true
  ignore_public_acls        = true
  restrict_public_buckets   = true

  enable_versioning         = each.value.versioning
  enable_encryption         = each.value.encryption
  
  # モジュールがライフサイクルポリシーなどを変数で受け取れるように拡張していれば、
  # ここで each.value から対応する変数を渡す
  # enable_lifecycle_rules = each.value.enable_lifecycle_rules
  # lifecycle_rules        = each.value.lifecycle_rules
}