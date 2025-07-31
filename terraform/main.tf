# s3のモジュール呼び出し
// --- フロントエンドアプリケーション用S3バケット ---
module "frontend_app_s3" {
  source = "./modules/s3"
  bucket_name               = "my-app-frontend-bucket-prod"
  tags = {
    Environment = "Production"
    Project     = "FrontendApp"
  }

  # 静的ファイルアップロード設定
  upload_static_files      = true
  static_files_source_path = "${path.module}/dist"
  
  # カスタムMIMEタイプがあれば追加
  mime_type_mapping = {
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".json" = "application/json"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".webp" = "image/webp"
    ".woff" = "font/woff"
    ".woff2" = "font/woff2"
  }
  
  # キャッシュ制御（フロントエンド用）
  cache_control = "public, max-age=31536000"  # 1年

  # ウェブサイトホスティング設定
  enable_website_hosting    = true
  index_document_suffix     = "index.html"
  error_document_key        = "index.html"
  enable_public_read_policy = true
  block_public_acls         = true
  block_public_policy       = false
  ignore_public_acls        = true
  restrict_public_buckets   = false
  enable_versioning         = true
  enable_encryption         = true
}

# ユーザーコンテンツ用バケットの作成
# バケット定義
locals {
  user_content_buckets = {
    # プロフィール画像（アバター）用
    "profile_pictures" = {
      bucket_name = "my-app-profile-pictures-bucket-prod"
      tags        = { 
        ContentType = "ProfilePictures"
        Purpose     = "UserAvatars"
      }
      versioning  = true
      encryption  = true

      # 厳格な制限
      allowed_mime_types = ["image/jpeg", "image/png", "image/webp"]
      max_file_size     = 2097152  # 2MB
      enable_cors       = true
      cors_origins      = ["https://yourdomain.com"]
      
      # プロフィール画像は長期保存
      lifecycle_rules = [
        {
          id = "delete_old_versions"
          enabled = true
          noncurrent_version_expiration_days = 30
        }
      ]
    },
    # ユーザーがアップロードする画像
    "user_documents" = {
      bucket_name = "my-app-user-documents-bucket-prod"
      tags        = { 
        ContentType = "UserImages"
        Purpose     = "GeneralImages"
      }
      versioning  = true
      encryption  = true

      # 画像のみ、サイズ制限緩め
      allowed_mime_types = [
        "image/jpeg", "image/png", "image/webp", 
        "image/gif", "image/svg+xml"
      ]
      max_file_size     = 10485760  # 10MB
      enable_cors       = true
      cors_origins      = ["https://yourdomain.com"]
      
      # 画像は長期保存、リサイズ処理用
      lifecycle_rules = [
        {
          id = "move_to_ia"
          enabled = true
          transition_days = 30
          storage_class = "STANDARD_IA"
        }
      ]
    },
    # 一時アップロード・処理用
    "temp_uploads" = {
      bucket_name = "my-app-temp-uploads-bucket-prod"
      tags        = { 
        ContentType = "TempFiles"
        Purpose     = "TemporaryProcessing"
      }
      versioning  = false  # 一時的なので不要
      encryption  = true

      # 一時的なので制限緩め
      allowed_mime_types = [
        "image/jpeg", "image/png", "image/webp", "image/gif",
        "application/pdf", "text/csv", "application/json",
        "application/zip", "text/plain"
      ]
      max_file_size     = 52428800  # 50MB
      enable_cors       = true
      cors_origins      = ["https://yourdomain.com"]
      
      # 短期間で自動削除
      lifecycle_rules = [
        {
          id = "auto_delete_temp_files"
          enabled = true
          expiration_days = 1  # 24時間で削除
        },
        {
          id = "cleanup_incomplete_multipart"
          enabled = true
          abort_incomplete_multipart_upload_days = 1
        }
      ]
    },
  }
}

// for_each を使ってモジュールを呼び出す
module "user_content_s3_buckets" {
  for_each = local.user_content_buckets
  source   = "./modules/s3"

  bucket_name               = each.value.bucket_name
  tags                      = merge({ Environment = "Production", Project = "UserContent" }, each.value.tags)

  # 静的ファイルアップロードは無効
  upload_static_files = false

  enable_website_hosting    = false
  enable_public_read_policy = false
  block_public_acls         = true
  block_public_policy       = true
  ignore_public_acls        = true
  restrict_public_buckets   = true

  enable_versioning         = each.value.versioning
  enable_encryption         = each.value.encryption
  
  lifecycle_rules        = each.value.lifecycle_rules
}

# Lambda関数
module "image_processor_lambda" {
  source = "./modules/lambda"
  
  function_name   = "user-content-processor"
  lambda_zip_file = "${path.module}/image_processor.zip"
  handler        = "index.handler"
  runtime        = "python3.9"
  timeout        = 300
  memory_size    = 512
  
  environment_variables = {
    PROFILE_BUCKET = module.user_content_s3_buckets["profile_pictures"].bucket_id
    IMAGES_BUCKET  = module.user_content_s3_buckets["user_documents"].bucket_id
    TEMP_BUCKET    = module.user_content_s3_buckets["temp_uploads"].bucket_id
  }
  
  s3_bucket_arns = [
    module.user_content_s3_buckets["profile_pictures"].bucket_arn,
    module.user_content_s3_buckets["user_documents"].bucket_arn,
    module.user_content_s3_buckets["temp_uploads"].bucket_arn
  ]
  
  tags = {
    Environment = "Production"
    Project     = "UserContent"
    Component   = "ImageProcessor"
  }
}

# S3-Lambda統合
module "temp_uploads_lambda_integration" {
  count  = contains(keys(local.user_content_buckets), "temp_uploads") ? 1 : 0
  source = "./modules/s3-lambda-integration"
  
  s3_bucket_id         = module.user_content_s3_buckets["temp_uploads"].bucket_id
  s3_bucket_arn        = module.user_content_s3_buckets["temp_uploads"].bucket_arn
  s3_bucket_name       = module.user_content_s3_buckets["temp_uploads"].bucket_id
  lambda_function_arn  = module.image_processor_lambda.function_arn
  lambda_function_name = module.image_processor_lambda.function_name
  
  lambda_events        = ["s3:ObjectCreated:*"]
  lambda_filter_prefix = "incoming/"
  statement_id         = "AllowS3InvokeLambda-temp-uploads"
  
  enable_notification = true
}

# 出力
output "lambda_function_arn" {
  description = "Lambda関数のARN"
  value       = module.image_processor_lambda.function_arn
}

output "integration_status" {
  description = "S3-Lambda統合の状態"
  value = length(module.temp_uploads_lambda_integration) > 0 ? {
    enabled = length(module.temp_uploads_lambda_integration[0].configured_events) > 0
    events  = module.temp_uploads_lambda_integration[0].configured_events
  } : null
}

# Amplifyアプリケーションモジュールの呼び出し
module "my_frontend_app" {
  count = var.environment == "local" ? 0 : 1

  source = "./modules/amplify" # モジュールのパスを指定

  app_name           = "my-awesome-amplify-app"
  repository_url     = "https://github.com/your-org/your-amplify-repo.git"
  github_oauth_token = var.github_access_token # ルートのvariables.tfから取得
  environment        = var.environment

  # 必要に応じてカスタムのビルドスペックを渡す
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: build # Create React Appのデフォルト出力ディレクトリ
        files:
          - '**/*'
    # キャッシュ設定などを追加することも可能
    # cache:
    #   paths:
    #     - node_modules/**/*
  EOT

  environment_variables = {
    #VITE_API_URL = "https://${module.my_backend_api.api_gateway_id}.execute-api.${data.aws_region.current.name}.amazonaws.com/prod"
    # 他の環境変数
  }

  custom_rules = [
    {
      source = "/<*>"
      target = "/index.html"
      status = "200"
    }
  ]

  tags = {
    Project     = "MyAwesomeApp"
    Environment = "Development"
  }

  branch_name = "main" # デプロイしたいブランチ名
  branch_stage = "DEVELOPMENT"
}

# 他のモジュール呼び出し (S3, Lambdaなど)
module "my_s3_bucket" {
  source = "./modules/s3"
  bucket_name = "my-unique-application-data-bucket"
}

# 例えば、Lambdaの環境変数にAmplifyのドメインを渡すことも可能
# module "my_lambda" {
#   source = "./modules/lambda"
#   function_name = "my-backend-function"
#   environment_variables = {
#     AMPLIFY_FRONTEND_URL = "https://${module.my_frontend_app.amplify_app_default_domain}"
#   }
#   # ... other variables
# }

# ECRモジュールの呼び出し
module "ecr" {
  count = var.environment == "local" ? 0 : 1 

  source          = "./modules/ecr"
  repository_name = "my-app-backend" # リポジトリ名を具体的に
  environment     = var.environment
  project_name    = var.project_name
  tags            = var.tags
}

# ECSクラスターモジュールの呼び出し
module "ecs_cluster" { # モジュール名をecs-clusterからecs_clusterに変更 (ハイフンは非推奨)
  count = var.environment == "local" ? 0 : 1

  source      = "./modules/ecs-cluster"
  cluster_name = "${var.project_name}-cluster-${var.environment}" # クラスター名を具体的に
  environment = var.environment
  project_name = var.project_name
  tags = var.tags
  # 必要に応じて、enable_fargate, enable_container_insights などを設定
  enable_fargate = true
  enable_container_insights = true
}

# ネットワークモジュールの呼び出し
module "network" {
  count = var.environment == "local" ? 0 : 1

  source        = "./modules/network"
  project_name  = var.project_name
  environment   = var.environment
  tags          = var.tags
  vpc_cidr_block = "10.0.0.0/16" # 環境に応じて変数化することも可能
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"] # 環境に応じて変数化することも可能

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"] # HTTPSアクセスを許可
    }
  ]
}

# ECS Fargateサービスモジュールの呼び出し
module "ecs_fargate_service" { # モジュール名をecs-fargateからecs_fargate_serviceに変更 (ハイフンは非推奨)
  count = var.environment == "local" ? 0 : 1

  source = "./modules/ecs-service-fargate"

  service_name = "${var.project_name}-backend-service-${var.environment}"
  # module.ecs_clusterはcountを持つため、[0]でアクセスします。
  # local環境でモジュールが存在しない可能性を考慮し、try() でラップします。
  cluster_name    = try(module.ecs_cluster[0].cluster_name, "") # ecs-clusterモジュールの出力を参照

  # module.ecrは countを持つため、[0]でアクセスします。
  # local環境でモジュールが存在しない可能性を考慮し、try() でラップします
  container_image = try(module.ecr[0].repository_url, "") # ECRモジュールの出力を参照

  # 必須のネットワーク設定
  subnets         = try(module.network[0].public_subnet_ids, []) # 上記で定義したサブネットのIDリスト
  security_groups = try([module.network[0].ecs_fargate_security_group_id], []) # 上記で定義したセキュリティグループのID

  # その他の必須ではないが、設定すべき変数
  cpu    = 256
  memory = 512
  container_port = 8080 # アプリケーションのポートに合わせる
  assign_public_ip = true # 必要であればパブリックIPを割り当てる

  # 環境変数やシークレット
  environment_variables = [
    { name = "APP_ENV", value = var.environment },
    { name = "DB_HOST", value = "my-database.example.com" }
  ]
  secrets = var.environment == "local" ? [] : [
  { 
    name = "DB_PASSWORD", 
    valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current[0].account_id}:parameter/my-app/db-password" 
  }
]

  # タグ
  environment = var.environment
  project_name = var.project_name
  tags        = var.tags
}

# DBインスタンスの設定
locals {
  database_configs = {
    # PostgreSQL データベース
    main_postgres = {
      engine                = "postgres"
      engine_version        = "14.7"
      instance_class        = "db.t3.small"
      allocated_storage     = 20
      db_name              = "maindb"
      username             = "appuser"
      password             = var.postgres_password
      port                 = 5432
      parameter_group_family = "postgres14"
      skip_final_snapshot  = var.environment == "dev" || var.environment == "local" ? true : false
      publicly_accessible  = false
      custom_parameters    = {
        "shared_buffers" = "256MB"
        "max_connections" = "100"
      }
    }
    
    # MySQL データベース (オプション)
    analytics_mysql = {
      engine                = "mysql"
      engine_version        = "8.0.35"
      instance_class        = "db.t3.micro"
      allocated_storage     = 20
      db_name              = "analytics"
      username             = "analytics_user"
      password             = var.mysql_password
      port                 = 3306
      parameter_group_family = "mysql8.0"
      skip_final_snapshot  = true
      publicly_accessible  = false
      custom_parameters    = {
        "innodb_buffer_pool_size" = "{DBInstanceClassMemory*3/4}"
      }
    }
    
    # 別のPostgreSQL (レポート用など)
    reporting_postgres = {
      engine                = "postgres"
      engine_version        = "15.4"
      instance_class        = "db.t3.medium"
      allocated_storage     = 50
      db_name              = "reporting"
      username             = "report_user"
      password             = var.reporting_db_password
      port                 = 5432
      parameter_group_family = "postgres15"
      skip_final_snapshot  = false
      publicly_accessible  = false
      custom_parameters    = {}
    }
  }
}

# RDSモジュールの呼び出し
module "rds_databases" {
  count = var.environment == "local" ? 0 : 1
  
  source = "./modules/rds"
  
  project_name          = var.project_name
  environment           = var.environment
  database_configs      = local.database_configs
  
  # networkモジュールからの出力を利用
  vpc_id                = module.network[0].vpc_id
  db_subnet_ids         = module.network[0].private_subnet_ids
  application_security_group_id = module.network[0].ecs_fargate_security_group_id
  
  tags = var.tags
}

# Auroraクラスターの設定
locals {
  aurora_configs = {
    # メインのAurora PostgreSQLクラスター
    main_aurora_postgres = {
      engine                = "aurora-postgresql"
      engine_version        = "14.9"
      cluster_identifier    = "${var.project_name}-aurora-postgres-${var.environment}"
      database_name         = "maindb"
      master_username       = "postgres"
      master_password       = var.aurora_postgres_password
      port                  = 5432
      
      # インスタンス設定
      instances = {
        writer = {
          instance_class = "db.r6g.large"
          publicly_accessible = false
        }
        reader = {
          instance_class = "db.r6g.large"
          publicly_accessible = false
        }
      }
      
      # バックアップ設定
      backup_retention_period = 7
      preferred_backup_window = "03:00-04:00"
      preferred_maintenance_window = "sun:04:00-sun:05:00"
      
      # セキュリティ設定
      storage_encrypted = true
      deletion_protection = var.environment == "prod" ? true : false
      skip_final_snapshot = var.environment == "dev" || var.environment == "local" ? true : false
      final_snapshot_identifier = var.environment == "prod" ? "${var.project_name}-aurora-postgres-final-snapshot-${var.environment}" : null
      
      # パフォーマンス設定
      performance_insights_enabled = true
      monitoring_interval = 60
      auto_minor_version_upgrade = false
      
      # スケーリング設定（サーバーレスv2の場合）
      serverlessv2_scaling_configuration = {
        max_capacity = 16
        min_capacity = 0.5
      }
      
      # パラメータグループ設定
      cluster_parameter_group_family = "aurora-postgresql14"
      db_parameter_group_family = "aurora-postgresql14"
      
      custom_cluster_parameters = {
        "shared_preload_libraries" = "pg_stat_statements"
        "log_statement" = "all"
        "log_min_duration_statement" = "1000"
      }
      
      custom_db_parameters = {
        "shared_buffers" = "{DBInstanceClassMemory/4}"
      }
    }
    
    # 分析用Aurora MySQLクラスター（オプション）
    analytics_aurora_mysql = {
      engine                = "aurora-mysql"
      engine_version        = "8.0.mysql_aurora.3.02.0"
      cluster_identifier    = "${var.project_name}-aurora-mysql-${var.environment}"
      database_name         = "analytics"
      master_username       = "admin"
      master_password       = var.aurora_mysql_password
      port                  = 3306
      
      # インスタンス設定
      instances = {
        writer = {
          instance_class = "db.r6g.xlarge"
          publicly_accessible = false
        }
      }
      
      # バックアップ設定
      backup_retention_period = 5
      preferred_backup_window = "03:00-04:00"
      preferred_maintenance_window = "sun:04:00-sun:05:00"
      
      # セキュリティ設定
      storage_encrypted = true
      deletion_protection = false
      skip_final_snapshot = true
      
      # パフォーマンス設定
      performance_insights_enabled = true
      monitoring_interval = 60
      auto_minor_version_upgrade = true
      
      # パラメータグループ設定
      cluster_parameter_group_family = "aurora-mysql8.0"
      db_parameter_group_family = "aurora-mysql8.0"
      
      custom_cluster_parameters = {
        "innodb_buffer_pool_size" = "{DBInstanceClassMemory*3/4}"
        "slow_query_log" = "1"
        "long_query_time" = "2"
      }
      
      custom_db_parameters = {}
    }
  }
}

# Auroraクラスターモジュールの呼び出し
module "aurora_clusters" {
  count = var.environment == "local" ? 0 : 1
  
  source = "./modules/aurora"
  
  project_name     = var.project_name
  environment      = var.environment
  aurora_configs   = local.aurora_configs
  
  # networkモジュールからの出力を利用（RDSと同じVPCを共有）
  vpc_id           = module.network[0].vpc_id
  db_subnet_ids    = module.network[0].private_subnet_ids
  application_security_group_id = module.network[0].ecs_fargate_security_group_id
  
  tags = var.tags
}


# 直接取得
data "aws_region" "current" {}
data "aws_caller_identity" "current" {
  count = var.environment == "local" ? 0 : 1
}