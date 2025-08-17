locals {
  environment  = "dev"
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
    "https://dev.yourdomain.com",
    "http://localhost:3000"
  ]
}

remote_state {
  backend = "remote"
  config = {
    organization = "sb-terraform"
    workspaces = {
      name = "mock_terraform_dev_data_processing"
    }
  }
}
