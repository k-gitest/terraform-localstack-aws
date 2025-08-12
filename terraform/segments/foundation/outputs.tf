output "vpc_id" {
  description = "The ID of the VPC."
  value       = var.environment == "local" ? "vpc-local" : module.network[0].vpc_id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets."
  value       = var.environment == "local" ? ["subnet-local-public-1", "subnet-local-public-2"] : module.network[0].public_subnet_ids
}

output "alb_security_group_id" {
  description = "The ID of the Security Group for the ALB."
  value       = var.environment == "local" ? "sg-local-alb" : module.network[0].alb_security_group_id
}

output "cluster_name" {
  description = "The name of the ECS cluster."
  value       = var.environment == "local" ? "ecs-cluster-local" : module.ecs_cluster[0].cluster_name
}

output "repository_url" {
  description = "The URL of the ECR repository."
  value       = var.environment == "local" ? "http://localhost:4566/ecr/local-repo" : module.ecr[0].repository_url
}

output "database_security_group_id" {
  description = "The ID of the Security Group for the database."
  value       = var.environment == "local" ? "sg-local-db" : module.network[0].database_security_group_id
}