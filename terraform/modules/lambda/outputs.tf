# Lambda関数の基本情報
output "function_arn" {
  description = "Lambda関数のARN"
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "Lambda関数の名前"
  value       = aws_lambda_function.this.function_name
}

output "function_invoke_arn" {
  description = "Lambda関数の呼び出しARN"
  value       = aws_lambda_function.this.invoke_arn
}

output "function_qualified_arn" {
  description = "Lambda関数の完全修飾ARN"
  value       = aws_lambda_function.this.qualified_arn
}

output "function_version" {
  description = "Lambda関数のバージョン"
  value       = aws_lambda_function.this.version
}

# IAMロール情報
output "lambda_role_arn" {
  description = "Lambda関数のIAMロールARN"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_role_name" {
  description = "Lambda関数のIAMロール名"
  value       = aws_iam_role.lambda_role.name
}

# その他の情報
output "function_last_modified" {
  description = "Lambda関数の最終更新日時"
  value       = aws_lambda_function.this.last_modified
}

output "function_source_code_hash" {
  description = "Lambda関数のソースコードハッシュ"
  value       = aws_lambda_function.this.source_code_hash
}

output "function_source_code_size" {
  description = "Lambda関数のソースコードサイズ"
  value       = aws_lambda_function.this.source_code_size
}