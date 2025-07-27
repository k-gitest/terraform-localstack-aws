# ECSクラスター情報
output "cluster_name" {
  description = "ECSクラスターの名前"
  value       = aws_ecs_cluster.this.name
}

output "cluster_id" {
  description = "ECSクラスターのID"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ECSクラスターのARN（Amazon Resource Name）"
  value       = aws_ecs_cluster.this.arn
}

# キャパシティプロバイダー情報
output "capacity_providers" {
  description = "クラスターに関連付けられたキャパシティプロバイダーのリスト"
  value       = local.capacity_providers
}

output "default_capacity_provider_strategy" {
  description = "クラスターのデフォルトキャパシティプロバイダー戦略"
  value       = var.default_capacity_provider_strategy
}

# 設定状態
output "container_insights_enabled" {
  description = "クラスターでContainer Insightsが有効かどうか"
  value       = var.enable_container_insights
}

output "execute_command_logging_enabled" {
  description = "execute commandログ記録が有効かどうか"
  value       = var.enable_execute_command_logging
}

# CloudWatchロググループ情報
output "execute_command_log_group_name" {
  description = "execute command用のCloudWatchロググループ名（作成された場合）"
  value       = var.enable_execute_command_logging && var.execute_command_log_group_name != "" ? aws_cloudwatch_log_group.execute_command[0].name : null
}

output "execute_command_log_group_arn" {
  description = "execute command用のCloudWatchロググループARN（作成された場合）"
  value       = var.enable_execute_command_logging && var.execute_command_log_group_name != "" ? aws_cloudwatch_log_group.execute_command[0].arn : null
}

# ECSサービス用
output "cluster_configuration" {
  description = "ECSサービス用の完全なクラスター設定"
  value = {
    cluster_name = aws_ecs_cluster.this.name
    cluster_arn  = aws_ecs_cluster.this.arn
    capacity_providers = local.capacity_providers
    container_insights_enabled = var.enable_container_insights
  }
}