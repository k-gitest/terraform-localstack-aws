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

  env_config = {
    backend_cpu               = 256
    backend_memory            = 512
    frontend_cpu              = 256
    frontend_memory           = 512
    backend_replicas          = 1
    frontend_replicas         = 1
    log_level                  = "debug"
    enable_https               = false
    enable_deletion_protection = false
  }

  cors_origins = [
    "http://localhost:3000",
    "http://127.0.0.1:3000"
  ]
}

remote_state {
  backend = "s3"
  config = {
    bucket = "your-terraform-state-bucket"
    key    = "data_processing/terraform.tfstate"
    region = "ap-northeast-1"

    endpoints = {
      s3 = "http://localhost:4566"
    }

    access_key = "test"
    secret_key = "test"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    use_path_style              = true
    skip_requesting_account_id  = true
  }
}
