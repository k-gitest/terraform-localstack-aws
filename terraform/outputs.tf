output "final_s3_bucket_name" {
  description = "The name of the S3 bucket created by the s3 module."
  value       = module.my_s3_bucket.bucket_name
}

output "final_s3_bucket_arn" {
  description = "The ARN of the S3 bucket created by the s3 module."
  value       = module.my_s3_bucket.bucket_arn
}