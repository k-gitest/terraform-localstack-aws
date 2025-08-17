locals {
  environment  = "prod"
  project_name = "my-awesome-app"

  common_tags = {
    Environment = local.environment
    Project     = local.project_name
    ManagedBy   = "terraform"
    Owner       = "DevOps"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  }

  env_config = {
    backend_cpu               = 1024
    backend_memory            = 2048
    frontend_cpu              = 512
    frontend_memory           = 1024
    backend_replicas          = 3
    frontend_replicas         = 2
    log_level                  = "info"
    enable_https               = true
    enable_deletion_protection = true
  }

  cors_origins = [
    "https://yourdomain.com",
    "https://www.yourdomain.com"
  ]
}

remote_state {
  backend = "remote"
  config = {
    organization = "sb-terraform"
    workspaces = {
      name = "mock_terraform_prod_data_processing"
    }
  }
}
