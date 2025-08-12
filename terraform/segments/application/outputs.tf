output "user_content_s3_buckets" {
  value = {
    for key, mod in module.user_content_s3_buckets :
    key => {
      bucket_name = mod.bucket_name
      bucket_arn  = mod.bucket_arn
    }
  }
}