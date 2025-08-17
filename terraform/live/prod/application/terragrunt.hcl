locals {
  environment   = "prod"
  project_name  = "my-awesome-app"

  common_tags = {
    Environment = local.environment
    Project     = local.project_name
    ManagedBy   = "terraform"
    Owner       = "DevOps"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  }

  cors_origins = [
    "https://yourdomain.com",
    "https://www.yourdomain.com"
  ]
}

terraform {
  cloud {
    organization = "sb-terraform"
    workspaces {
      name = "mock_terraform_prod"
    }
  }
}
