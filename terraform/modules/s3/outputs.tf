output "bucket_name" {
  description = "The name of the created S3 bucket."
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "The ARN of the created S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_id" {
  description = "The ID (name) of the created S3 bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_region" {
  description = "The AWS region where the S3 bucket is located."
  value       = aws_s3_bucket.this.region
}