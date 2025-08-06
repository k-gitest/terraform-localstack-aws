output "bucket_name" {
  description = "作成されたS3バケットの名前"
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "作成されたS3バケットのARN（Amazon Resource Name）"
  value       = aws_s3_bucket.this.arn
}

output "bucket_id" {
  description = "作成されたS3バケットのID（名前）"
  value       = aws_s3_bucket.this.id
}

output "bucket_region" {
  description = "S3バケットが配置されているAWSリージョン"
  value       = aws_s3_bucket.this.region
}

output "s3_bucket_domain_name" {
  description = "The domain name of the created S3 bucket."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}
