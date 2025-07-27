output "frontend_app_s3_bucket_name" {
  description = "フロントエンドアプリケーション用S3バケットの名前"  
  value       = module.frontend_app_s3.bucket_id # modules/s3/outputs.tf で bucket_id と定義している場合
}

output "frontend_app_s3_bucket_arn" {
  description = "フロントエンドアプリケーション用S3バケットのARN"
  value       = module.frontend_app_s3.bucket_arn # modules/s3/outputs.tf で bucket_arn と定義している場合
}

# ユーザーコンテンツのプロファイル画像バケットの例 (for_each で作成されたモジュールからの出力)
output "profile_pictures_bucket_name" {
  description = "プロファイル画像用S3バケットの名前"
  value       = module.user_content_s3_buckets["profile_pictures"].bucket_id
}

output "profile_pictures_bucket_arn" {
  description = "プロファイル画像用S3バケットのARN"
  value       = module.user_content_s3_buckets["profile_pictures"].bucket_arn
}