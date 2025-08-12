# コンピュート関連のlocals

locals {
  # Lambda設定
  lambda_functions = {
    image_processor = {
      name = "${var.project_name}-image-processor-${var.environment}"
      handler = "index.handler"
      runtime = "python3.11"
      timeout = var.environment == "prod" ? 300 : 60
      memory = var.environment == "prod" ? 1024 : 512
      user_content_s3_buckets = data.terraform_remote_state.application.outputs.user_content_s3_buckets
      
      environment = {
        ENVIRONMENT = var.environment
        LOG_LEVEL = local.env_config.log_level
        PROJECT = var.project_name
        MAX_IMAGE_SIZE = "10485760"
        ALLOWED_FORMATS = "jpg,jpeg,png,webp,gif"
        THUMBNAIL_SIZES = "150x150,300x300,600x600"
      }
    }
    
    auth_validator = {
      name = "${var.project_name}-auth-validator-${var.environment}"
      handler = "index.handler"
      runtime = "nodejs18.x"
      timeout = 30
      memory = 256
      
      environment = {
        ENVIRONMENT = var.environment
        LOG_LEVEL = local.env_config.log_level
        PROJECT = var.project_name
        TOKEN_EXPIRY = var.environment == "prod" ? "3600" : "86400"
      }
    }
  }

}