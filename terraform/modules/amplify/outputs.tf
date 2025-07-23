output "amplify_app_id" {
  description = "The ID of the Amplify application."
  value       = aws_amplify_app.this.id
}

output "amplify_app_arn" {
  description = "The ARN of the Amplify application."
  value       = aws_amplify_app.this.arn
}

output "amplify_app_default_domain" {
  description = "The default domain for the Amplify application."
  value       = aws_amplify_app.this.default_domain
}

output "amplify_app_name" {
  description = "The name of the Amplify application."
  value       = aws_amplify_app.this.name
}

output "amplify_branch_name" {
  description = "The name of the connected branch."
  value       = aws_amplify_branch.this.branch_name
}