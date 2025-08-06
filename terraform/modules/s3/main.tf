terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # または "> 5.0"
    }
  }
}

# === S3バケット本体は一つだけ定義 ===
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = var.tags 
}

# 作成したバケットのオーナーシップ権限設定
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# === 静的ファイルアップロード機能 ===
resource "aws_s3_object" "static_files" {
  for_each = var.upload_static_files ? fileset(var.static_files_source_path, "**/*") : []
  
  bucket = aws_s3_bucket.this.id
  key    = each.value
  source = "${var.static_files_source_path}/${each.value}"
  
  # MIMEタイプの自動判定
  content_type = lookup(
    var.mime_type_mapping,
    regex("\\.[^.]+$", each.value),
    var.default_mime_type
  )
  
  # キャッシュ制御
  cache_control = var.cache_control
  
  # ファイルハッシュでバージョン管理
  etag = filemd5("${var.static_files_source_path}/${each.value}")
}

// === 静的サイトのホスティング設定 (enable_website_hosting が true の場合のみ作成) ===
resource "aws_s3_bucket_website_configuration" "this" {
  count  = var.enable_website_hosting ? 1 : 0
  bucket = aws_s3_bucket.this.id # <-- このモジュールで作成した aws_s3_bucket.this を参照

  index_document {
    suffix = var.index_document_suffix
  }
  error_document {
    key = var.error_document_key
  }
}

// === バケットのパブリックアクセスブロック設定 (変数で制御) ===
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id # <-- このモジュールで作成した aws_s3_bucket.this を参照
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

resource "aws_s3_bucket_policy" "this" {
  count  = local.current_config.create_policy ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = jsonencode(local.current_config.policy_document)
}

# 作成したバケットのバージョニング設定
resource "aws_s3_bucket_versioning" "this" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.this.id # <-- このモジュールで作成した aws_s3_bucket.this を参照
  versioning_configuration {
    status = "Enabled"
  }
}

# 作成したバケットの暗号化設定 (enable_encryption が true の場合のみ作成)
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.this.id # <-- このモジュールで作成した aws_s3_bucket.this を参照
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# バケットのライフサイクル設定 (lifecycle_rules が空でない場合のみ作成)
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      # 必ず filter ブロックを追加し、空の filter を指定する
      # もし特定のプレフィックスでフィルタリングしたい場合は、filter { prefix = "my-prefix/" } のように設定します。
      filter {}

      dynamic "expiration" {
        for_each = lookup(rule.value, "expiration_days", null) != null ? [1] : []
        content {
          days = rule.value.expiration_days
        }
      }
    }
  }
}