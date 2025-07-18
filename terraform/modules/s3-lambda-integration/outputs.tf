# Lambda権限の情報
output "lambda_permission_statement_id" {
  description = "Lambda権限のステートメントID"
  value       = aws_lambda_permission.allow_s3_to_invoke_lambda.statement_id
}

output "lambda_permission_id" {
  description = "Lambda権限のID"
  value       = aws_lambda_permission.allow_s3_to_invoke_lambda.id
}

# S3バケット通知の情報
output "bucket_notification_id" {
  description = "S3バケット通知のID"
  value       = aws_s3_bucket_notification.lambda_trigger.id
}

# 統合設定の確認情報
output "configured_events" {
  description = "設定されているS3イベント"
  value       = var.lambda_events
}

output "configured_filter_prefix" {
  description = "設定されているフィルタープレフィックス"
  value       = var.lambda_filter_prefix
}

output "configured_filter_suffix" {
  description = "設定されているフィルターサフィックス"
  value       = var.lambda_filter_suffix
}