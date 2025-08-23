include "stack" {
  path = find_in_parent_folders("terragrunt.hcl")
  expose = true
}

terraform {
  source = "${include.stack.locals.module_root}/cloudfront"
}

inputs = {
  project_name   = include.stack.locals.project_name
  environment    = include.stack.locals.environment
  bucket_type    = each.key
  
  # S3バケットのドメイン名を取得
  s3_bucket_domain_name = each.key == "frontend" ? module.frontend_app_s3.s3_bucket_domain_name : module.user_content_s3_buckets[each.key].s3_bucket_domain_name
  
  # CloudFront設定
  default_cache_behavior        = each.value.cache_behavior
  origin_access_control_enabled = each.value.origin_access_control_enabled
  default_root_object          = each.value.default_root_object
  custom_error_responses       = each.value.custom_error_responses
  
  # タグ
  tags = merge(
    include.stack.locals.common_tags,
    {
      Module = basename(get_terragrunt_dir())
    }
  )
}
