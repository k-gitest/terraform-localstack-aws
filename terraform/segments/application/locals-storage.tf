# S3・ストレージ関連のlocals

locals {
  # S3バケット設定
  s3_buckets = {
    frontend = {
      name = "${var.project_name}-frontend-bucket-${var.environment}"
      versioning = true
      encryption = true
      website_hosting = true
      #public_read = true
      policy_type = var.environment == "local" ? "public-read" : "cloudfront-oac"
    }
    
    user_content = {
      profile_pictures = {
        name = "${var.project_name}-profile-pictures-${var.environment}"
        versioning = true
        encryption = true
        max_file_size = 2097152  # 2MB
        allowed_types = ["image/jpeg", "image/png", "image/webp"]
        lifecycle_days = 30
        policy_type = "private"
      }
      
      user_documents = {
        name = "${var.project_name}-user-documents-${var.environment}"
        versioning = true
        encryption = true
        max_file_size = 10485760  # 10MB
        allowed_types = ["image/jpeg", "image/png", "image/webp", "image/gif", "image/svg+xml"]
        lifecycle_days = 90
        policy_type = "private"
      }
      
      temp_uploads = {
        name = "${var.project_name}-temp-uploads-${var.environment}"
        versioning = false
        encryption = true
        max_file_size = 52428800  # 50MB
        allowed_types = [
          "image/jpeg", "image/png", "image/webp", "image/gif",
          "application/pdf", "text/csv", "application/json",
          "application/zip", "text/plain"
        ]
        auto_delete_days = 1
        policy_type = "private"
      }
    }
  }

    # Amplifyアプリケーションの共通設定
  amplify_app = {
    app_name            = "my-awesome-amplify-app"
    repository_url      = "https://github.com/your-org/your-amplify-repo.git"
    branch_name         = "main"
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
          baseDirectory: build
          files:
            - '**/*'
    EOT
    custom_rules = [
      {
        source = "/<*>"
        target = "/index.html"
        status = "200"
      }
    ]

    # 環境ごとの設定
    branch_stage = var.environment == "prod" ? "PRODUCTION" : "DEVELOPMENT"
    environment_variables = {
      # 環境ごとの変数
      #VITE_API_URL = "https://${local.api_gateway_id}.execute-api.${local.aws_region}.amazonaws.com/prod"
    }
  }


  # CloudFrontを適用するバケットの設定
  cloudfront_enabled_buckets = var.environment == "local" ? {} : {
    # フロントエンド用
    frontend = {
      cache_behavior = {
        default_ttl = 86400      # 1日
        max_ttl     = 31536000   # 1年
        min_ttl     = 0
        compress    = true
      }
      origin_access_control_enabled = true
      default_root_object = "index.html"
      custom_error_responses = [
        {
          error_code         = 404
          response_code      = 200
          response_page_path = "/index.html"
          error_caching_min_ttl = 300
        },
        {
          error_code         = 403
          response_code      = 200
          response_page_path = "/index.html"
          error_caching_min_ttl = 300
        }
      ]
    }
    
    # プロフィール画像用（条件付き適用）
    profile_pictures = {
    cache_behavior = {
    default_ttl = 604800     # 1週間
    max_ttl     = 31536000   # 1年
    min_ttl     = 86400      # 1日
    compress    = true
    }
    origin_access_control_enabled = true
    default_root_object = null
    custom_error_responses = [
    {
    error_code         = 404
    response_code      = 404
    response_page_path = null
    error_caching_min_ttl = 300
     }
    ]
    }
  }

  # MIME Type設定
  mime_types = {
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
}