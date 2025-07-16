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