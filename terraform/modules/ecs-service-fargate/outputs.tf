output "ecs_service_name" {
  description = "The name of the ECS service."
  value       = aws_ecs_service.this.name
}

/*
output "ecs_service_arn" {
  description = "The ARN of the ECS service."
  value       = aws_ecs_service.this.arn
}
*/

output "ecs_task_definition_arn" {
  description = "The ARN of the ECS task definition."
  value       = aws_ecs_task_definition.this.arn
}

output "ecs_task_execution_role_arn" {
  description = "The ARN of the ECS task execution IAM role."
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "The ARN of the ECS task IAM role."
  value       = aws_iam_role.ecs_task_role.arn
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group for the ECS service."
  value       = aws_cloudwatch_log_group.ecs_log_group.name
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group for the ECS service."
  value       = aws_cloudwatch_log_group.ecs_log_group.arn
}

output "service_discovery_service_arn" {
  description = "The ARN of the AWS Cloud Map service discovery service (if enabled)."
  value       = var.enable_service_discovery ? aws_service_discovery_service.this[0].arn : null
}

output "service_discovery_service_name" {
  description = "The name of the AWS Cloud Map service discovery service (if enabled)."
  value       = var.enable_service_discovery ? aws_service_discovery_service.this[0].name : null
}