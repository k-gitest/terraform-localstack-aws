include "stack" {
  path = find_in_parent_folders("terragrunt.hcl")
  expose = true
}

terraform {
  source = "${include.stack.locals.module_root}/s3"
}

inputs = {
  bucket_name = include.stack.locals.s3_buckets.frontend.name
  enable_website_hosting = include.stack.locals.s3_buckets.frontend.website_hosting

  policy_type = include.stack.locals.s3_buckets.frontend.policy_type

  enable_versioning = include.stack.locals.s3_buckets.frontend.versioning
  enable_encryption = include.stack.locals.s3_buckets.frontend.encryption
  
  upload_static_files = true
  static_files_source_path = "${path.module}/dist"
  # mime_type_mapping = local.mime_types
  cache_control = "public, max-age=31536000"
  
  index_document_suffix = "index.html"
  error_document_key = "index.html"
  
  block_public_acls = true
  block_public_policy = false
  ignore_public_acls = true
  restrict_public_buckets = false
    
  # タグ
  tags = merge(
    include.stack.locals.common_tags,
    {
      Module = basename(get_terragrunt_dir())
    }
  )
}
