include "stack" {
  path = find_in_parent_folders("terragrunt.hcl")
  expose = true
}

terraform {
  source = "${include.stack.locals.module_root}/cloudfront"
}

dependency "user_content_s3" {
  config_path = "../../s3/user-content"
  mock_outputs = {
    s3_buckets = {
      profile_pictures = {
        domain_name = "mock-profile-pictures.s3.amazonaws.com"
      }
    }
  }
}

inputs = {
  project_name                  = include.stack.locals.project_name
  environment                   = include.stack.locals.environment
  bucket_type                   = "profile_pictures"

  s3_bucket_domain_name         = dependency.user_content_s3.outputs.s3_buckets[local.bucket_type].domain_name
  
  # CloudFront設定
  default_cache_behavior        = include.stack.locals.cloudfront_enabled_buckets.profile_pictures.cache_behavior
  origin_access_control_enabled = include.stack.locals.cloudfront_enabled_buckets.profile_pictures.origin_access_control_enabled
  default_root_object           = include.stack.locals.cloudfront_enabled_buckets.profile_pictures.default_root_object
  custom_error_responses        = include.stack.locals.cloudfront_enabled_buckets.profile_pictures.custom_error_responses
  
  # タグ
  tags = merge(
    include.stack.locals.common_tags,
    {
      Module = basename(get_terragrunt_dir())
    }
  )
}
