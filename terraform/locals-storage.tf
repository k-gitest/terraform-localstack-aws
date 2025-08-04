# S3・ストレージ関連のlocals

locals {
  # S3バケット設定
  s3_buckets = {
    frontend = {
      name = "${var.project_name}-frontend-bucket-${var.environment}"
      versioning = true
      encryption = true
      website_hosting = true
      public_read = true
    }
    
    user_content = {
      profile_pictures = {
        name = "${var.project_name}-profile-pictures-${var.environment}"
        versioning = true
        encryption = true
        max_file_size = 2097152  # 2MB
        allowed_types = ["image/jpeg", "image/png", "image/webp"]
        lifecycle_days = 30
      }
      
      user_documents = {
        name = "${var.project_name}-user-documents-${var.environment}"
        versioning = true
        encryption = true
        max_file_size = 10485760  # 10MB
        allowed_types = ["image/jpeg", "image/png", "image/webp", "image/gif", "image/svg+xml"]
        lifecycle_days = 90
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
      }
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