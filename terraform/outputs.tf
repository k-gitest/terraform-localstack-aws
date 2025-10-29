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

# ===================================
# GitHub Secrets設定用の統合出力
# ===================================
# フロント・バックエンドアプリケーション用: GitHub Secrets設定用の統合出力
output "github_repository_secrets" {
  description = "GitHub リポジトリに設定すべきSecrets（コピー&ペースト用）"
  
  value = {
    # ===================================
    # IaCリポジトリ用（Terraform実行）
    # ===================================
    iac = {
      for env in var.environments : env => {
        AWS_ROLE_ARN               = data.terraform_remote_state.bootstrap.outputs.github_actions_role_arns[env]
        AWS_REGION                 = var.aws_region
      }
    }
    
    # ===================================
    # フロントエンドリポジトリ用
    # ===================================
    frontend = {
      for env in var.environments : env => {
        AWS_ROLE_ARN               = data.terraform_remote_state.bootstrap.outputs.github_actions_frontend_role_arns[env]
        AWS_REGION                 = var.aws_region
        S3_BUCKET_NAME             = try(module.frontend[env].s3_bucket_name, "")
        CLOUDFRONT_DISTRIBUTION_ID = try(module.frontend[env].cloudfront_distribution_id, "")
      }
    }
    
    # ===================================
    # バックエンドリポジトリ用
    # ===================================
    backend = {
      for env in var.environments : env => {
        AWS_ROLE_ARN       = data.terraform_remote_state.bootstrap.outputs.github_actions_backend_role_arns[env]
        AWS_REGION         = var.aws_region
        ECR_REPOSITORY_URL = try(module.ecr[env].repository_url, "")
        ECS_CLUSTER_NAME   = try(module.ecs_cluster[env].cluster_name, "")
        ECS_SERVICE_NAME   = try(module.ecs_service[env].service_name, "")
      }
    }
  }
}

# sns/sqsの出力定義
output "sns_topic_arns" {
  description = "SNSトピックのARNのマップ"
  value = {
    for k, v in module.sns_topics : k => v.sns_topic_arn
  }
}

output "sqs_queue_arns" {
  description = "SQSキューのARNのマップ"
  value = {
    for k, v in module.sqs_queues : k => v.sqs_queue_arn
  }
}

output "sqs_queue_urls" {
  description = "SQSキューのURLのマップ"
  value = {
    for k, v in module.sqs_queues : k => v.sqs_queue_url
  }
}