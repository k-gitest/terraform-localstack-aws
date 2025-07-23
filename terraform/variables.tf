variable "aws_region" {
  description = "The AWS region to deploy resources to."
  type        = string
  default     = "ap-northeast-1" # LocalStack で一般的に使用されるリージョン
}

variable "github_access_token" {
  description = "GitHub OAuth token for private repositories (for Amplify). Recommended to load from environment variable or secret manager."
  type        = string
  sensitive   = true
}

# ECR/ECS/Fargateの変数設定
variable "environment" {
  description = "Environment name (e.g., local, dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "my-backend-app" # プロジェクト名を具体的に
}

variable "tags" {
  description = "A map of tags to assign to all resources."
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
