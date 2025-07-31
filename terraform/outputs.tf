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

# Aurora接続情報の出力
output "aurora_cluster_endpoints" {
  description = "Auroraクラスターのエンドポイント情報"
  value = var.environment == "local" ? {} : {
    for cluster_name, cluster_config in local.aurora_configs : cluster_name => {
      cluster_endpoint = module.aurora_clusters[0].cluster_endpoints[cluster_name]
      reader_endpoint  = module.aurora_clusters[0].reader_endpoints[cluster_name]
      port            = cluster_config.port
      database_name   = cluster_config.database_name
    }
  }
  sensitive = false
}

output "aurora_cluster_identifiers" {
  description = "Auroraクラスター識別子"
  value = var.environment == "local" ? {} : {
    for cluster_name, cluster_config in local.aurora_configs : cluster_name => 
      module.aurora_clusters[0].cluster_identifiers[cluster_name]
  }
}