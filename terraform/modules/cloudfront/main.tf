resource "aws_cloudfront_distribution" "this" {
  origin {
    domain_name              = var.s3_bucket_domain_name
    origin_access_control_id = var.origin_access_control_enabled ? aws_cloudfront_origin_access_control.this[0].id : null
    origin_id                = "s3-origin-${var.bucket_type}"
    
    # フロントエンド以外でOACを使わない場合のS3オリジン設定
    dynamic "s3_origin_config" {
      for_each = !var.origin_access_control_enabled ? [1] : []
      content {
        origin_access_identity = ""
      }
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront distribution for ${var.bucket_type} - ${var.project_name} ${var.environment}"
  
  # フロントエンドの場合のみdefault_root_objectを設定
  default_root_object = var.bucket_type == "frontend" ? var.default_root_object : null

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin-${var.bucket_type}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = var.default_cache_behavior.compress
    
    # バケットタイプに応じてallowed_methodsを調整
    allowed_methods = var.bucket_type == "frontend" ? ["GET", "HEAD"] : ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    
    # TTL設定
    default_ttl = var.default_cache_behavior.default_ttl
    max_ttl     = var.default_cache_behavior.max_ttl
    min_ttl     = var.default_cache_behavior.min_ttl

    forwarded_values {
      query_string = var.bucket_type != "frontend" # ユーザーコンテンツの場合はクエリパラメータを転送
      cookies {
        forward = "none"
      }
      
      # 認証が必要な場合のヘッダー転送
      headers = var.bucket_type != "frontend" ? ["Authorization", "CloudFront-Viewer-Country"] : []
    }
  }

  # フロントエンド用のカスタムエラーレスポンス（SPA対応）
  dynamic "custom_error_response" {
    for_each = var.bucket_type == "frontend" ? [
      {
        error_code            = 404
        response_code         = 200
        response_page_path    = "/index.html"
        error_caching_min_ttl = 300
      },
      {
        error_code            = 403
        response_code         = 200
        response_page_path    = "/index.html"
        error_caching_min_ttl = 300
      }
    ] : var.custom_error_responses
    
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
  
  tags = var.tags
}

# OACリソース（条件付きで作成）
resource "aws_cloudfront_origin_access_control" "this" {
  count = var.origin_access_control_enabled ? 1 : 0
  
  name                              = "${var.project_name}-oac-${var.bucket_type}-${var.environment}"
  description                       = "OAC for ${var.bucket_type} bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}