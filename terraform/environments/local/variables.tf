variable "aws_region" {
  description = "The AWS region to deploy resources to."
  type        = string
  default     = "ap-northeast-1"
}

variable "github_access_token" {
  description = "GitHub OAuth token for private repositories (for Amplify). Recommended to load from environment variable or secret manager."
  type        = string
  sensitive   = true
}

variable "container_image" {
  description = "Complete Docker image URI including tag"
  type        = string
  default     = null
}