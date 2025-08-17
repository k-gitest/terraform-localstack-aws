locals {
  environment   = "dev"
  project_name  = "my-awesome-app"

  common_tags = {
    Environment = local.environment
    Project     = local.project_name
    ManagedBy   = "terraform"
    Owner       = "DevOps"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  }

  cors_origins = [
    "https://dev.yourdomain.com",
    "http://localhost:3000"
  ]
}

terraform {
  cloud {
    organization = "sb-terraform"
    workspaces {
      name = "mock_terraform_dev"
    }
  }
}
