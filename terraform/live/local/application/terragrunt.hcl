locals {
  environment   = "local"
  project_name  = "my-awesome-app"

  common_tags = {
    Environment = local.environment
    Project     = local.project_name
    ManagedBy   = "terraform"
    Owner       = "DevOps"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  }

  # CORS設定（ローカル用）
  cors_origins = [
    "http://localhost:3000",
    "http://127.0.0.1:3000"
  ]
}

terraform {
  source = "../../modules//application"
}
