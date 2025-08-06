variable "bucket_name" {
  description = "作成するS3バケットの名前"
  type        = string
}

variable "tags" {
  description = "バケットに割り当てるタグのマップ"
  type        = map(string)
  default     = {}
}

variable "upload_example_object" {
  description = "バケットにサンプルオブジェクトをアップロードするかどうか"
  type        = bool
  default     = false
}

variable "block_public_access" {
  description = "S3バケットへのすべてのパブリックアクセスをブロックするかどうか"
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
  description = "バケットで静的ウェブサイトホスティングを有効にするかどうか"
  type        = bool
  default     = false # 通常は無効
}

variable "index_document_suffix" {
  description = "ウェブサイトホスティング用のインデックスドキュメント名（例：index.html）"
  type        = string
  default     = "index.html" # デフォルト値
}

variable "error_document_key" {
  description = "ウェブサイトホスティング用のエラードキュメント名（例：error.html）"
  type        = string
  default     = "error.html" # SPAの場合は index.html にオーバーライドする
}

variable "policy_type" {
  description = "バケットポリシーのタイプ（例：public_read, private, custom）"
  type        = string
  default     = "private"
  validation {
    condition = contains(["private", "public_read", "cloudfront_oac"], var.policy_type)
    error_message = "Policy type must be one of: none, public_read, cloudfront_oac."
  }
}

variable "cloudfront_distribution_arn" {
  description = "CloudFrontディストリビューションのARN（OACポリシーを使用する場合に必要）"
  type        = string
  default     = null # デフォルトはnull（OACポリシーを使用しない）
}

variable "block_public_acls" {
  description = "S3バケットのパブリックACLをブロックするかどうか"
  type        = bool
  default     = true # デフォルトはブロック (セキュリティベストプラクティス)
}

variable "block_public_policy" {
  description = "S3バケットのパブリックバケットポリシーをブロックするかどうか"
  type        = bool
  default     = true # デフォルトはブロック (セキュリティベストプラクティス)
}

variable "ignore_public_acls" {
  description = "S3バケット内のオブジェクトのパブリックACLを無視するかどうか"
  type        = bool
  default     = true # デフォルトは無視 (セキュリティベストプラクティス)
}

variable "restrict_public_buckets" {
  description = "S3バケットのパブリックアクセスを制限するかどうか"
  type        = bool
  default     = true # デフォルトは制限 (セキュリティベストプラクティス)
}

// ライフサイクルルールも追加するなら
variable "lifecycle_rules" {
  description = "バケットのライフサイクルルールのリスト。空でない場合のみ適用される"
  type = list(object({
    id            = string
    enabled       = bool
    expiration_days = optional(number)
  }))
  default = []
}

# === 静的ファイルアップロード用変数 ===
variable "upload_static_files" {
  description = "バケットに静的ファイルをアップロードするかどうか"
  type        = bool
  default     = false
}

variable "static_files_source_path" {
  description = "静的ファイルが格納されているディレクトリのパス"
  type        = string
  default     = ""
}

variable "mime_type_mapping" {
  description = "ファイル拡張子とMIMEタイプのマッピング"
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
  description = "不明なファイル拡張子に対するデフォルトのMIMEタイプ"
  type        = string
  default     = "application/octet-stream"
}

variable "cache_control" {
  description = "静的ファイル用のキャッシュコントロールヘッダー"
  type        = string
  default     = "public, max-age=86400"
}