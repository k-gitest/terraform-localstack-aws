resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = var.tags
}

# バケットオーナーシップ
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# バケットオブジェクト
resource "aws_s3_object" "example" {
  count  = var.upload_example_object ? 1 : 0
  bucket = aws_s3_bucket.this.id
  key    = "example.txt"
  source = "${path.module}/files/example.txt"
}

// S3バケットのパブリックアクセスブロック設定
resource "aws_s3_bucket_public_access_block" "this" {
  count                   = var.block_public_access ? 1 : 0
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3バケットのバージョニング設定（必要に応じて）
resource "aws_s3_bucket_versioning" "this" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3バケットの暗号化設定（必要に応じて）
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}