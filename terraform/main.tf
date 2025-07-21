# s3のモジュール呼び出し
// --- フロントエンドアプリケーション用S3バケット ---
module "frontend_app_s3" {
  source = "./modules/s3"
  bucket_name               = "my-app-frontend-bucket-prod"
  tags = {
    Environment = "Production"
    Project     = "FrontendApp"
  }

  # 静的ファイルアップロード設定
  upload_static_files      = true
  static_files_source_path = "${path.module}/dist"
  
  # カスタムMIMEタイプがあれば追加
  mime_type_mapping = {
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".json" = "application/json"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".webp" = "image/webp"
    ".woff" = "font/woff"
    ".woff2" = "font/woff2"
  }
  
  # キャッシュ制御（フロントエンド用）
  cache_control = "public, max-age=31536000"  # 1年

  # ウェブサイトホスティング設定
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
    # プロフィール画像（アバター）用
    "profile_pictures" = {
      bucket_name = "my-app-profile-pictures-bucket-prod"
      tags        = { 
        ContentType = "ProfilePictures"
        Purpose     = "UserAvatars"
      }
      versioning  = true
      encryption  = true

      # 厳格な制限
      allowed_mime_types = ["image/jpeg", "image/png", "image/webp"]
      max_file_size     = 2097152  # 2MB
      enable_cors       = true
      cors_origins      = ["https://yourdomain.com"]
      
      # プロフィール画像は長期保存
      lifecycle_rules = [
        {
          id = "delete_old_versions"
          enabled = true
          noncurrent_version_expiration_days = 30
        }
      ]
    },
    # ユーザーがアップロードする画像
    "user_documents" = {
      bucket_name = "my-app-user-documents-bucket-prod"
      tags        = { 
        ContentType = "UserImages"
        Purpose     = "GeneralImages"
      }
      versioning  = true
      encryption  = true

      # 画像のみ、サイズ制限緩め
      allowed_mime_types = [
        "image/jpeg", "image/png", "image/webp", 
        "image/gif", "image/svg+xml"
      ]
      max_file_size     = 10485760  # 10MB
      enable_cors       = true
      cors_origins      = ["https://yourdomain.com"]
      
      # 画像は長期保存、リサイズ処理用
      lifecycle_rules = [
        {
          id = "move_to_ia"
          enabled = true
          transition_days = 30
          storage_class = "STANDARD_IA"
        }
      ]
    },
    # 一時アップロード・処理用
    "temp_uploads" = {
      bucket_name = "my-app-temp-uploads-bucket-prod"
      tags        = { 
        ContentType = "TempFiles"
        Purpose     = "TemporaryProcessing"
      }
      versioning  = false  # 一時的なので不要
      encryption  = true

      # 一時的なので制限緩め
      allowed_mime_types = [
        "image/jpeg", "image/png", "image/webp", "image/gif",
        "application/pdf", "text/csv", "application/json",
        "application/zip", "text/plain"
      ]
      max_file_size     = 52428800  # 50MB
      enable_cors       = true
      cors_origins      = ["https://yourdomain.com"]
      
      # 短期間で自動削除
      lifecycle_rules = [
        {
          id = "auto_delete_temp_files"
          enabled = true
          expiration_days = 1  # 24時間で削除
        },
        {
          id = "cleanup_incomplete_multipart"
          enabled = true
          abort_incomplete_multipart_upload_days = 1
        }
      ]
    },
  }
}

// for_each を使ってモジュールを呼び出す
module "user_content_s3_buckets" {
  for_each = local.user_content_buckets
  source   = "./modules/s3"

  bucket_name               = each.value.bucket_name
  tags                      = merge({ Environment = "Production", Project = "UserContent" }, each.value.tags)

  # 静的ファイルアップロードは無効
  upload_static_files = false

  enable_website_hosting    = false
  enable_public_read_policy = false
  block_public_acls         = true
  block_public_policy       = true
  ignore_public_acls        = true
  restrict_public_buckets   = true

  enable_versioning         = each.value.versioning
  enable_encryption         = each.value.encryption
  
  lifecycle_rules        = each.value.lifecycle_rules
}

# Lambda関数
module "image_processor_lambda" {
  source = "./modules/lambda"
  
  function_name   = "user-content-processor"
  lambda_zip_file = "image_processor.zip"
  handler        = "index.handler"
  runtime        = "python3.9"
  timeout        = 300
  memory_size    = 512
  
  environment_variables = {
    PROFILE_BUCKET = module.user_content_s3_buckets["profile_pictures"].bucket_id
    IMAGES_BUCKET  = module.user_content_s3_buckets["user_documents"].bucket_id
    TEMP_BUCKET    = module.user_content_s3_buckets["temp_uploads"].bucket_id
  }
  
  s3_bucket_arns = [
    module.user_content_s3_buckets["profile_pictures"].bucket_arn,
    module.user_content_s3_buckets["user_documents"].bucket_arn,
    module.user_content_s3_buckets["temp_uploads"].bucket_arn
  ]
  
  tags = {
    Environment = "Production"
    Project     = "UserContent"
    Component   = "ImageProcessor"
  }
}

# S3-Lambda統合
module "temp_uploads_lambda_integration" {
  count  = contains(keys(local.user_content_buckets), "temp_uploads") ? 1 : 0
  source = "./modules/s3-lambda-integration"
  
  s3_bucket_id         = module.user_content_s3_buckets["temp_uploads"].bucket_id
  s3_bucket_arn        = module.user_content_s3_buckets["temp_uploads"].bucket_arn
  s3_bucket_name       = module.user_content_s3_buckets["temp_uploads"].bucket_id
  lambda_function_arn  = module.image_processor_lambda.function_arn
  lambda_function_name = module.image_processor_lambda.function_name
  
  lambda_events        = ["s3:ObjectCreated:*"]
  lambda_filter_prefix = "incoming/"
  statement_id         = "AllowS3InvokeLambda-temp-uploads"
  
  enable_notification = true
}

# 出力
output "lambda_function_arn" {
  description = "Lambda関数のARN"
  value       = module.image_processor_lambda.function_arn
}

output "integration_status" {
  description = "S3-Lambda統合の状態"
  value = length(module.temp_uploads_lambda_integration) > 0 ? {
    enabled = length(module.temp_uploads_lambda_integration[0].configured_events) > 0
    events  = module.temp_uploads_lambda_integration[0].configured_events
  } : null
}

# Amplifyアプリケーションモジュールの呼び出し
data "aws_region" "current" {}

module "my_frontend_app" {
  source = "./modules/amplify" # モジュールのパスを指定

  app_name           = "my-awesome-amplify-app"
  repository_url     = "https://github.com/your-org/your-amplify-repo.git"
  github_oauth_token = var.github_access_token # ルートのvariables.tfから取得

  # 必要に応じてカスタムのビルドスペックを渡す
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: build # Create React Appのデフォルト出力ディレクトリ
        files:
          - '**/*'
    # キャッシュ設定などを追加することも可能
    # cache:
    #   paths:
    #     - node_modules/**/*
  EOT

  environment_variables = {
    #VITE_API_URL = "https://${module.my_backend_api.api_gateway_id}.execute-api.${data.aws_region.current.name}.amazonaws.com/prod"
    # 他の環境変数
  }

  custom_rules = [
    {
      source = "/<*>"
      target = "/index.html"
      status = "200"
    }
  ]

  tags = {
    Project     = "MyAwesomeApp"
    Environment = "Development"
  }

  branch_name = "main" # デプロイしたいブランチ名
  branch_stage = "DEVELOPMENT"
}

# 他のモジュール呼び出し (S3, Lambdaなど)
module "my_s3_bucket" {
  source = "./modules/s3"
  bucket_name = "my-unique-application-data-bucket"
  # ... other variables
}

# 例えば、Lambdaの環境変数にAmplifyのドメインを渡すことも可能
# module "my_lambda" {
#   source = "./modules/lambda"
#   function_name = "my-backend-function"
#   environment_variables = {
#     AMPLIFY_FRONTEND_URL = "https://${module.my_frontend_app.amplify_app_default_domain}"
#   }
#   # ... other variables
# }