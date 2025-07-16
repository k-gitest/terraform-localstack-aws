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

# 作成したバケットのオブジェクトアップロード設定 (これは通常モジュール外で管理)
# resource "aws_s3_object" "example" {
#   count  = var.upload_example_object ? 1 : 0
#   bucket = aws_s3_bucket.this.id
#   key    = "example.txt"
#   source = "${path.module}/files/example.txt"
# }

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

// === バケットポリシーの設定 (enable_public_read_policy が true の場合のみ作成) ===
resource "aws_s3_bucket_policy" "this" {
  count  = var.enable_public_read_policy ? 1 : 0
  bucket = aws_s3_bucket.this.id # <-- このモジュールで作成した aws_s3_bucket.this を参照
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.this.arn}/*"
      },
    ]
  })
}

# 作成したバケットのバージョニング設定 (enable_versioning が true の場合のみ作成)
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

      dynamic "expiration" {
        for_each = lookup(rule.value, "expiration_days", null) != null ? [1] : []
        content {
          days = rule.value.expiration_days
        }
      }
    }
  }
}

