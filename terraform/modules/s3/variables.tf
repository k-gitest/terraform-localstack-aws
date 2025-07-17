variable "bucket_name" {
  description = "The name of the S3 bucket to create."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}

variable "upload_example_object" {
  description = "Whether to upload an example object to the bucket."
  type        = bool
  default     = false
}

variable "block_public_access" {
  description = "Whether to block all public access to the S3 bucket."
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "バケットのバージョニングを有効にするかどうか"
  type        = bool
  default     = false
}

variable "enable_encryption" {
  description = "バケットの暗号化を有効にするかどうか"
  type        = bool
  default     = true
}

variable "enable_website_hosting" {
  description = "Set to true to enable static website hosting on the bucket."
  type        = bool
  default     = false # 通常は無効
}

variable "index_document_suffix" {
  description = "The name of the index document (e.g., index.html) for website hosting."
  type        = string
  default     = "index.html" # デフォルト値
}

variable "error_document_key" {
  description = "The name of the error document (e.g., error.html) for website hosting."
  type        = string
  default     = "error.html" # SPAの場合は index.html にオーバーライドする
}

variable "enable_public_read_policy" {
  description = "Set to true to attach a public read policy to the bucket (required for static websites unless using CloudFront OAI/OAC)."
  type        = bool
  default     = false # 通常は無効
}

variable "block_public_acls" {
  description = "Whether to block public ACLs for the S3 bucket."
  type        = bool
  default     = true # デフォルトはブロック (セキュリティベストプラクティス)
}

variable "block_public_policy" {
  description = "Whether to block public bucket policies for the S3 bucket."
  type        = bool
  default     = true # デフォルトはブロック (セキュリティベストプラクティス)
}

variable "ignore_public_acls" {
  description = "Whether to ignore public ACLs on objects for the S3 bucket."
  type        = bool
  default     = true # デフォルトは無視 (セキュリティベストプラクティス)
}

variable "restrict_public_buckets" {
  description = "Whether to restrict public buckets for the S3 bucket."
  type        = bool
  default     = true # デフォルトは制限 (セキュリティベストプラクティス)
}

// ライフサイクルルールも追加するなら
variable "lifecycle_rules" {
  description = "A list of lifecycle rules for the bucket. Only applied if not empty."
  type = list(object({
    id            = string
    enabled       = bool
    expiration_days = optional(number)
  }))
  default = []
}

# === 静的ファイルアップロード用変数 ===
variable "upload_static_files" {
  description = "Whether to upload static files to the bucket"
  type        = bool
  default     = false
}

variable "static_files_source_path" {
  description = "Path to the directory containing static files"
  type        = string
  default     = ""
}

variable "mime_type_mapping" {
  description = "Mapping of file extensions to MIME types"
  type        = map(string)
  default = {
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
    ".pdf"  = "application/pdf"
    ".txt"  = "text/plain"
    ".webp" = "image/webp"
  }
}

variable "default_mime_type" {
  description = "Default MIME type for unknown file extensions"
  type        = string
  default     = "application/octet-stream"
}

variable "cache_control" {
  description = "Cache control header for static files"
  type        = string
  default     = "public, max-age=86400"
}

# Lambdaトリガー関連変数
/*
variable "lambda_trigger_enabled" {
  description = "Set to true to enable Lambda triggers for this S3 bucket."
  type        = bool
  default     = false
}

variable "lambda_function_arn" {
  description = "The ARN of the Lambda function to trigger."
  type        = string
  default     = null # トリガーが有効な場合のみ必須
}

variable "lambda_events" {
  description = "A list of S3 events that will trigger the Lambda function (e.g., [\"s3:ObjectCreated:*\", \"s3:ObjectRemoved:*\"])."
  type        = list(string)
  default     = ["s3:ObjectCreated:*"] # デフォルトでオブジェクト作成イベントに設定
}

variable "lambda_filter_prefix" {
  description = "Object key prefix to filter events."
  type        = string
  default     = null
}

variable "lambda_filter_suffix" {
  description = "Object key suffix to filter events."
  type        = string
  default     = null
}
*/