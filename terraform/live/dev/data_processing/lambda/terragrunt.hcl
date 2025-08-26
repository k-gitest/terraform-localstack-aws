include {
  path = find_in_parent_folders()
  expose = true
}

terraform {
  source = "${include.stack.locals.module_root}/lambda"
}

dependency "application" {
  config_path = "../../application/s3/profile_pictures"
}

inputs = {
  function_name = include.stack.locals.lambda_functions.image_processor.name
  lambda_zip_file = "${path.module}/image_processor.zip"
  handler = include.stack.locals.lambda_functions.image_processor.handler
  runtime = include.stack.locals.lambda_functions.image_processor.runtime
  timeout = include.stack.locals.lambda_functions.image_processor.timeout
  memory_size = include.stack.locals.lambda_functions.image_processor.memory
  
  environment_variables = include.stack.locals.lambda_functions.image_processor.environment
  
  s3_bucket_arns = [
    for bucket in dependency.application.outputs.user_content_s3_buckets : bucket.bucket_arn
  ]

  # タグ
  tags = merge(
    include.stack.locals.common_tags,
    {
      Module = basename(get_terragrunt_dir())
    }
  )
}
