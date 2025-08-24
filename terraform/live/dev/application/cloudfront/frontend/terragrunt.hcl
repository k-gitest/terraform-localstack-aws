include "stack" {
  path = find_in_parent_folders("terragrunt.hcl")
  expose = true
}

terraform {
  source = "${include.stack.locals.module_root}/cloudfront"
}

dependency "frontend_s3" {
  config_path = "../../s3/frontend"
  mock_outputs = {
    s3_bucket_domain_name = "mock-frontend-app.s3.amazonaws.com"
  }
}

inputs = {
  project_name                  = include.stack.locals.project_name
  environment                   = include.stack.locals.environment
  bucket_type                   = "frontend"

  s3_bucket_domain_name         = dependency.frontend_s3.outputs.s3_bucket_domain_name
  
  # CloudFront設定
  default_cache_behavior        = include.stack.locals.cloudfront_enabled_buckets.frontend.cache_behavior
  origin_access_control_enabled = include.stack.locals.cloudfront_enabled_buckets.frontend.origin_access_control_enabled
  default_root_object           = include.stack.locals.cloudfront_enabled_buckets.frontend.default_root_object
  custom_error_responses        = include.stack.locals.cloudfront_enabled_buckets.frontend.custom_error_responses
  
  # タグ
  tags = merge(
    include.stack.locals.common_tags,
    {
      Module = basename(get_terragrunt_dir())
    }
  )
}
