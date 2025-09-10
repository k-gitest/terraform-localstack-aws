# S3モジュール
module "frontend_app_s3" {
  source = "../../modules/s3"
  
  bucket_name = local.s3_buckets.frontend.name
  enable_website_hosting = local.s3_buckets.frontend.website_hosting

  policy_type = local.s3_buckets.frontend.policy_type

  enable_versioning = local.s3_buckets.frontend.versioning
  enable_encryption = local.s3_buckets.frontend.encryption
  
  upload_static_files = true
  static_files_source_path = "${path.module}/dist"
  mime_type_mapping = local.mime_types
  cache_control = "public, max-age=31536000"
  
  index_document_suffix = "index.html"
  error_document_key = "index.html"
  
  block_public_acls = true
  block_public_policy = false
  ignore_public_acls = true
  restrict_public_buckets = false
  
  tags = local.common_tags
}

# ユーザーコンテンツS3バケット
module "user_content_s3_buckets" {
  for_each = local.s3_buckets.user_content
  source = "../../modules/s3"

  bucket_name = each.value.name
  enable_versioning = each.value.versioning
  enable_encryption = each.value.encryption
  
  upload_static_files = false
  enable_website_hosting = false
  policy_type = each.value.policy_type
  
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
  
  lifecycle_rules = lookup(each.value, "lifecycle_days", null) != null ? [
    {
      id = "auto_delete"
      enabled = true
      expiration_days = each.value.lifecycle_days
    }
  ] : []
  
  tags = merge(local.common_tags, {
    ContentType = each.key
  })
}

# CloudFrontモジュール
module "cloudfront" {
  for_each = local.cloudfront_enabled_buckets
  source = "../../modules/cloudfront"

  project_name   = var.project_name
  environment    = var.environment
  bucket_type    = each.key
  
  # S3バケットのドメイン名を取得
  s3_bucket_domain_name = each.key == "frontend" ? module.frontend_app_s3.s3_bucket_domain_name : module.user_content_s3_buckets[each.key].s3_bucket_domain_name
  
  # CloudFront設定
  default_cache_behavior        = each.value.cache_behavior
  origin_access_control_enabled = each.value.origin_access_control_enabled
  default_root_object          = each.value.default_root_object
  custom_error_responses       = each.value.custom_error_responses
  
  tags = merge(local.common_tags, {
    BucketType = each.key
  })
}

# ALBモジュール
module "alb" {
  count = var.environment == "local" ? 0 : 1
  source = "../../modules/alb"
  
  project_name = var.project_name
  environment = var.environment
  
  alb_name = local.alb_config.name
  internal = local.alb_config.internal
  
  # subnets = try(module.network[0].public_subnet_ids, [])
  # security_groups = try([module.network[0].alb_security_group_id], [])
  # vpc_id = try(module.network[0].vpc_id, "")

  # ここを remote_state の出力に修正
  subnets = data.terraform_remote_state.foundation.outputs.public_subnet_ids
  security_groups = [data.terraform_remote_state.foundation.outputs.alb_security_group_id]
  vpc_id = data.terraform_remote_state.foundation.outputs.vpc_id
  
  target_groups = local.alb_config.target_groups
  default_target_group = local.alb_config.default_target_group
  listener_rules = local.alb_config.listener_rules
  
  enable_https = local.env_config.enable_https
  enable_deletion_protection = local.alb_config.enable_deletion_protection
  
  tags = local.common_tags
}

# ECS Fargateサービス
module "ecs_fargate_service" {
  count = var.environment == "local" ? 0 : 1
  source = "../../modules/ecs-service-fargate"

  service_name = "${var.project_name}-backend-service-${var.environment}"
  
  # cluster_name = try(module.ecs_cluster[0].cluster_name, "")
  # container_image = try(module.ecr[0].repository_url, "")

  cluster_name = data.terraform_remote_state.foundation.outputs.cluster_name
  # container_image = data.terraform_remote_state.foundation.outputs.repository_url
  
  # 条件分岐：外部から渡された場合はそれを使用、そうでなければデフォルト
  container_image = var.container_image != null ? var.container_image : data.terraform_remote_state.foundation.outputs.repository_url
  
  # リソース設定
  cpu = local.env_config.backend_cpu
  memory = local.env_config.backend_memory
  container_port = local.app_config.backend_port
  assign_public_ip = true
  
  # ネットワーク設定
  # subnets = try(module.network[0].public_subnet_ids, [])
  # security_groups = try([module.network[0].application_security_group_id], [])
  # vpc_id = try(module.network[0].vpc_id, "")

  # ここを remote_state の出力に修正
  subnets = data.terraform_remote_state.foundation.outputs.public_subnet_ids
  security_groups = [data.terraform_remote_state.foundation.outputs.alb_security_group_id]
  vpc_id = data.terraform_remote_state.foundation.outputs.vpc_id
  
  # ALB統合
  enable_load_balancer = true
  target_group_arn = try(module.alb[0].target_group_arns["backend"], "")
  
  # セキュリティグループ設定
  # alb_security_group_id = try(module.network[0].alb_security_group_id, "")
  # database_security_group_id = try(module.network[0].database_security_group_id, "")
  
  alb_security_group_id = data.terraform_remote_state.foundation.outputs.alb_security_group_id
  database_security_group_id = data.terraform_remote_state.foundation.outputs.database_security_group_id
  database_port = 5432
  enable_public_internet_egress = true
  
  # アプリケーション設定
  environment_variables = local.backend_env_vars
  secrets = local.backend_secrets
  
  environment = var.environment
  project_name = var.project_name
  tags = local.common_tags
}

# フロントエンド
module "amplify_app" {
  count = var.environment == "local" ? 0 : 1

  source = "../../modules/amplify"

  # locals から共通設定を参照
  app_name            = local.amplify_app.app_name
  repository_url      = local.amplify_app.repository_url
  build_spec          = local.amplify_app.build_spec
  custom_rules        = local.amplify_app.custom_rules
  branch_name         = local.amplify_app.branch_name

  # 環境変数とタグは、環境固有のlocalsを参照
  environment_variables = local.amplify_app.environment_variables
  branch_stage          = local.amplify_app.branch_stage

  tags                  = local.common_tags

  # その他、環境に依存する変数
  github_oauth_token  = var.github_access_token
  environment         = var.environment
}

# データソース
data "aws_region" "current" {}
data "aws_caller_identity" "current" {
  count = var.environment == "local" ? 0 : 1
}