output "vpc_id" {
  description = "The ID of the VPC."
  value       = "vpc-local"
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets."
  value       = ["subnet-local-public-1", "subnet-local-public-2"]
}

output "alb_security_group_id" {
  description = "The ID of the Security Group for the ALB."
  value       = "sg-local-alb"
}

output "cluster_name" {
  description = "The name of the ECS cluster."
  value       = "ecs-cluster-local"
}

output "repository_url" {
  description = "The URL of the ECR repository."
  value       = "http://localhost:4566/ecr/local-repo"
}

output "database_security_group_id" {
  description = "The ID of the Security Group for the database."
  value       = "sg-local-db"
}