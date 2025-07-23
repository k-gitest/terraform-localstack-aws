# ECS Cluster Information
output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.this.arn
}

# Capacity Provider Information
output "capacity_providers" {
  description = "List of capacity providers associated with the cluster"
  value       = local.capacity_providers
}

output "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy for the cluster"
  value       = var.default_capacity_provider_strategy
}

# Configuration Status
output "container_insights_enabled" {
  description = "Whether Container Insights is enabled for the cluster"
  value       = var.enable_container_insights
}

output "execute_command_logging_enabled" {
  description = "Whether execute command logging is enabled"
  value       = var.enable_execute_command_logging
}

# CloudWatch Log Group Information
output "execute_command_log_group_name" {
  description = "CloudWatch log group name for execute command (if created)"
  value       = var.enable_execute_command_logging && var.execute_command_log_group_name != "" ? aws_cloudwatch_log_group.execute_command[0].name : null
}

output "execute_command_log_group_arn" {
  description = "CloudWatch log group ARN for execute command (if created)"
  value       = var.enable_execute_command_logging && var.execute_command_log_group_name != "" ? aws_cloudwatch_log_group.execute_command[0].arn : null
}

# Useful for ECS Services
output "cluster_configuration" {
  description = "Complete cluster configuration for ECS services"
  value = {
    cluster_name = aws_ecs_cluster.this.name
    cluster_arn  = aws_ecs_cluster.this.arn
    capacity_providers = local.capacity_providers
    container_insights_enabled = var.enable_container_insights
  }
}