output "amplify_app_id" {
  description = "AmplifyアプリケーションのID"
  value       = aws_amplify_app.this.id
}

output "amplify_app_arn" {
  description = "AmplifyアプリケーションのARN（Amazon Resource Name）"
  value       = aws_amplify_app.this.arn
}

output "amplify_app_default_domain" {
  description = "Amplifyアプリケーションのデフォルトドメイン"
  value       = aws_amplify_app.this.default_domain
}

output "amplify_app_name" {
  description = "Amplifyアプリケーションの名前"
  value       = aws_amplify_app.this.name
}

output "amplify_branch_name" {
  description = "接続されたブランチの名前"
  value       = aws_amplify_branch.this.branch_name
}