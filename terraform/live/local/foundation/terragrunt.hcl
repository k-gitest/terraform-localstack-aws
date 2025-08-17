terraform {
  # foundation 配下の modules をまとめて読み込む場合
  source = "../../../modules/foundation"
}

locals {
  environment  = "local"
  project_name = "my-awesome-app"

  common_tags = {
    Environment = local.environment
    Project     = local.project_name
    ManagedBy   = "terraform"
    Owner       = "DevOps"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  }

  cors_origins = local.environment == "prod" ? [
    "https://yourdomain.com",
    "https://www.yourdomain.com"
  ] : local.environment == "dev" ? [
    "https://dev.yourdomain.com",
    "http://localhost:3000"
  ] : [
    "http://localhost:3000",
    "http://127.0.0.1:3000"
  ]
}

inputs = {
  environment   = local.environment
  project_name  = local.project_name
  common_tags   = local.common_tags
  cors_origins  = local.cors_origins
}
