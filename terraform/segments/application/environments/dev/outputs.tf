output "user_content_s3_buckets" {
  description = "Outputs for the user content S3 buckets"
  value       = module.app_infrastructure.user_content_s3_buckets
}