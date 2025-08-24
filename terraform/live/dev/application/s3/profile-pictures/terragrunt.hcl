include "stack" {
  path = find_in_parent_folders("terragrunt.hcl")
  expose = true
}

terraform {
  source = "${include.stack.locals.module_root}/s3"
}

inputs = {
  bucket_name = include.stack.locals.s3_buckets.profile_pictures.name
  enable_versioning = include.stack.locals.s3_buckets.profile_pictures.versioning
  enable_encryption = include.stack.locals.s3_buckets.profile_pictures.encryption
  
  upload_static_files = false
  enable_website_hosting = false
  policy_type = include.stack.locals.s3_buckets.profile_pictures.policy_type
  
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
  
  lifecycle_rules = [
    {
      id = "auto_delete"
      enabled = true
      expiration_days = 30
    }
  ]
    
  # タグ
  tags = merge(
    include.stack.locals.common_tags,
    {
      Module = basename(get_terragrunt_dir())
    }
  )
}
