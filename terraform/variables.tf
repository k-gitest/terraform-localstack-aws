variable "aws_region" {
  description = "The AWS region to deploy resources to."
  type        = string
  default     = "us-east-1" # LocalStack で一般的に使用されるリージョン
}

variable "github_access_token" {
  description = "GitHub OAuth token for private repositories (for Amplify). Recommended to load from environment variable or secret manager."
  type        = string
  sensitive   = true
}