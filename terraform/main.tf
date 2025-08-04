# S3モジュール
module "frontend_app_s3" {
  source = "./modules/s3"
  
  bucket_name = local.s3_buckets.frontend.name
  enable_website_hosting = local.s3_buckets.frontend.website_hosting
  enable_public_read_policy = local.s3_buckets.frontend.public_read
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
  source = "./modules/s3"

  bucket_name = each.value.name
  enable_versioning = each.value.versioning
  enable_encryption = each.value.encryption
  
  upload_static_files = false
  enable_website_hosting = false
  enable_public_read_policy = false
  
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

# ネットワークモジュール
module "network" {
  count = var.environment == "local" ? 0 : 1
  source = "./modules/network"
  
  project_name = var.project_name
  environment = var.environment
  
  vpc_cidr_block = local.network_config.vpc_cidr
  public_subnet_cidrs = local.network_config.public_subnet_cidrs
  private_subnet_cidrs = local.network_config.private_subnet_cidrs
  
  tags = local.common_tags
}

# ECRモジュール
module "ecr" {
  count = var.environment == "local" ? 0 : 1
  source = "./modules/ecr"
  
  repository_name = local.ecr_repositories.backend
  environment = var.environment
  project_name = var.project_name
  tags = local.common_tags
}

# ECSクラスターモジュール
module "ecs_cluster" {
  count = var.environment == "local" ? 0 : 1
  source = "./modules/ecs-cluster"
  
  cluster_name = local.ecs_cluster.name
  enable_fargate = local.ecs_cluster.enable_fargate
  enable_container_insights = local.ecs_cluster.enable_container_insights
  
  environment = var.environment
  project_name = var.project_name
  tags = local.common_tags
}

# ALBモジュール
module "alb" {
  count = var.environment == "local" ? 0 : 1
  source = "./modules/alb"
  
  project_name = var.project_name
  environment = var.environment
  
  alb_name = local.alb_config.name
  internal = local.alb_config.internal
  subnets = try(module.network[0].public_subnet_ids, [])
  security_groups = try([module.network[0].alb_security_group_id], [])
  vpc_id = try(module.network[0].vpc_id, "")
  
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
  source = "./modules/ecs-service-fargate"

  service_name = "${var.project_name}-backend-service-${var.environment}"
  cluster_name = try(module.ecs_cluster[0].cluster_name, "")
  container_image = try(module.ecr[0].repository_url, "")
  
  # リソース設定
  cpu = local.env_config.backend_cpu
  memory = local.env_config.backend_memory
  container_port = local.app_config.backend_port
  assign_public_ip = true
  
  # ネットワーク設定
  subnets = try(module.network[0].public_subnet_ids, [])
  security_groups = try([module.network[0].application_security_group_id], [])
  vpc_id = try(module.network[0].vpc_id, "")
  
  # ALB統合
  enable_load_balancer = true
  target_group_arn = try(module.alb[0].target_group_arns["backend"], "")
  
  # セキュリティグループ設定
  alb_security_group_id = try(module.network[0].alb_security_group_id, "")
  database_security_group_id = try(module.network[0].database_security_group_id, "")
  database_port = 5432
  enable_public_internet_egress = true
  
  # アプリケーション設定
  environment_variables = local.backend_env_vars
  secrets = local.backend_secrets
  
  environment = var.environment
  project_name = var.project_name
  tags = local.common_tags
}

# Lambda関数
module "image_processor_lambda" {
  source = "./modules/lambda"
  
  function_name = local.lambda_functions.image_processor.name
  lambda_zip_file = "${path.module}/image_processor.zip"
  handler = local.lambda_functions.image_processor.handler
  runtime = local.lambda_functions.image_processor.runtime
  timeout = local.lambda_functions.image_processor.timeout
  memory_size = local.lambda_functions.image_processor.memory
  
  environment_variables = local.lambda_functions.image_processor.environment
  
  s3_bucket_arns = [
    for bucket in module.user_content_s3_buckets : bucket.bucket_arn
  ]
  
  tags = local.common_tags
}

# RDSデータベース
module "rds_databases" {
  count = var.environment == "local" ? 0 : 1
  source = "./modules/rds"
  
  project_name = var.project_name
  environment = var.environment
  database_configs = try(local.rds_configs, {})
  
  vpc_id = module.network[0].vpc_id
  db_subnet_ids = module.network[0].private_subnet_ids
  db_subnet_group_name = module.network[0].db_subnet_group_name
  application_security_group_id = module.network[0].application_security_group_id
  database_security_group_id = module.network[0].database_security_group_id
  
  tags = local.common_tags
}

# Auroraクラスター
module "aurora_clusters" {
  count = var.environment == "local" ? 0 : 1
  source = "./modules/aurora"
  
  project_name = var.project_name
  environment = var.environment
  aurora_configs = try(local.aurora_configs, {})
  
  vpc_id                        = module.network[0].vpc_id
  db_subnet_ids                 = module.network[0].private_subnet_ids
  db_subnet_group_name          = module.network[0].db_subnet_group_name
  application_security_group_id = module.network[0].application_security_group_id
  database_security_group_id    = module.network[0].database_security_group_id
  
  tags = local.common_tags
}

# データソース
data "aws_region" "current" {}
data "aws_caller_identity" "current" {
  count = var.environment == "local" ? 0 : 1
}