output "ecs_service_name" {
  description = "ECSサービスの名前"
  value       = aws_ecs_service.this.name
}

/* output "ecs_service_arn" {
  description = "ECSサービスのARN（Amazon Resource Name）"
  value       = aws_ecs_service.this.arn
} */

output "ecs_task_definition_arn" {
  description = "ECSタスク定義のARN"
  value       = aws_ecs_task_definition.this.arn
}

output "ecs_task_execution_role_arn" {
  description = "ECSタスク実行用IAMロールのARN"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ECSタスク用IAMロールのARN"
  value       = aws_iam_role.ecs_task_role.arn
}

output "cloudwatch_log_group_name" {
  description = "ECSサービス用のCloudWatchロググループ名"
  value       = aws_cloudwatch_log_group.ecs_log_group.name
}

output "cloudwatch_log_group_arn" {
  description = "ECSサービス用のCloudWatchロググループARN"
  value       = aws_cloudwatch_log_group.ecs_log_group.arn
}

output "service_discovery_service_arn" {
  description = "AWS Cloud MapサービスディスカバリーサービスのARN（有効な場合）"
  value       = var.enable_service_discovery ? aws_service_discovery_service.this[0].arn : null
}

output "service_discovery_service_name" {
  description = "AWS Cloud Mapサービスディスカバリーサービスの名前（有効な場合）"
  value       = var.enable_service_discovery ? aws_service_discovery_service.this[0].name : null
}

output "target_group_arn" {
  description = "The ARN of the ALB target group created for this ECS service."
  value       = var.enable_load_balancer ? aws_lb_target_group.this[0].arn : null
}

output "fargate_sg_id" {
  description = "Fargate security group ID"
  value       = aws_security_group.fargate.id
}