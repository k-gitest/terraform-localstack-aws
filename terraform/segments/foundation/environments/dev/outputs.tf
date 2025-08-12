output "vpc_id" {
  description = "The ID of the VPC."
  value       = module.app_infrastructure.vpc_id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets."
  value       = module.app_infrastructure.public_subnet_ids
}

output "alb_security_group_id" {
  description = "The ID of the Security Group for the ALB."
  value       = module.app_infrastructure.alb_security_group_id
}

output "cluster_name" {
  description = "The name of the ECS cluster."
  value       = module.app_infrastructure.cluster_name
}

output "repository_url" {
  description = "The URL of the ECR repository."
  value       = module.app_infrastructure.repository_url
}

output "database_security_group_id" {
  description = "The ID of the Security Group for the database."
  value       = module.app_infrastructure.database_security_group_id
}