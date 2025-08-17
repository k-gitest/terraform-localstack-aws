include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/data-processing/lambda"
}

locals {
  lambda_functions = {
    image_processor = {
      name   = "${local.project_name}-image-processor-${local.environment}"
      handler = "index.handler"
      runtime = "python3.11"
      timeout = 300
      memory  = 1024
      user_content_s3_buckets = dependency.application.outputs.user_content_s3_buckets

      environment = {
        ENVIRONMENT       = local.environment
        LOG_LEVEL         = local.env_config.log_level
        PROJECT           = local.project_name
        MAX_IMAGE_SIZE    = "10485760"
        ALLOWED_FORMATS   = "jpg,jpeg,png,webp,gif"
        THUMBNAIL_SIZES   = "150x150,300x300,600x600"
      }
    }

    auth_validator = {
      name   = "${local.project_name}-auth-validator-${local.environment}"
      handler = "index.handler"
      runtime = "nodejs18.x"
      timeout = 30
      memory  = 256

      environment = {
        ENVIRONMENT = local.environment
        LOG_LEVEL   = local.env_config.log_level
        PROJECT     = local.project_name
        TOKEN_EXPIRY = "3600"
      }
    }
  }
}

dependency "application" {
  config_path = "../../application"
}

inputs = {
  environment      = local.environment
  project_name     = local.project_name
  common_tags      = local.common_tags
  lambda_functions = local.lambda_functions
}
