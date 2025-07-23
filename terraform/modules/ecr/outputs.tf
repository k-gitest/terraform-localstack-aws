# ECR Repository Information
output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.this.name
}

output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.this.arn
}

output "registry_id" {
  description = "Registry ID where the repository was created"
  value       = aws_ecr_repository.this.registry_id
}

# Useful for Docker commands
output "repository_uri_with_tag" {
  description = "Repository URI with latest tag (useful for Docker commands)"
  value       = "${aws_ecr_repository.this.repository_url}:latest"
}

output "docker_login_command" {
  description = "AWS CLI command to authenticate Docker with ECR"
  value       = "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${aws_ecr_repository.this.repository_url}"
}

# Policy Information
output "lifecycle_policy_created" {
  description = "Whether lifecycle policy was created"
  value       = var.enable_lifecycle_policy
}

output "repository_policy_created" {
  description = "Whether repository policy was created"
  value       = var.enable_cross_account_access && length(var.allowed_account_ids) > 0
}

# Data source for current region
data "aws_region" "current" {}