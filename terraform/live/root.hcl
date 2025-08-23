# 共通変数の設定
locals {
  project_name = "my-awesome-project"
  aws_region = "ap-northeast-1"
  github_access_token = ""

  # 現在の環境名を取得
  # "dev/foundation/network" → "dev"
  relative_path = path_relative_to_include()
  path_parts    = split("/", local.relative_path)
  environment = try(local.path_parts[0], null)
  segment     = try(local.path_parts[1], null)
  service     = try(local.path_parts[2], null)

  # workspace名の設定
  workspace_name = join("-", compact([
    "mock-terraform",
    local.environment,
    local.segment,
    local.service
  ]))

  # modulesへのパス設定
  module_root = "${get_repo_root()}/terraform/modules"

  # tags設定
  common_tags = {
    Project   = local.project_name
    ManagedBy = "terragrunt"
    Owner     = "DevOps"
    CreatedAt = formatdate("YYYY-MM-DD", timestamp())
    Env       = local.environment
  }

  # データベースの共通デフォルト値(dev用)を定義
  database_configs = {
    main_postgres = {
      engine              = "postgres"
      engine_version      = "14.7"
      instance_class      = "db.t3.small" # デフォルト値（dev用）
      storage             = 20           # デフォルト値（dev用）
      db_name             = "maindb"
      username            = "appuser"
      port                = 5432
      family              = "postgres14"
      skip_snapshot       = true         # デフォルト値（dev用）
      publicly_accessible = false
      backup_retention    = 1            # デフォルト値（dev用）
      backup_window       = "03:00-04:00"
      maintenance_window  = "sun:04:00-sun:05:00"
    }

    analytics_mysql = {
      engine         = "mysql"
      engine_version = "8.0.35"
      instance_class = "db.t3.micro"
      storage        = 20
      db_name        = "analytics"
      username       = "analytics_user"
      port          = 3306
      family        = "mysql8.0"
      skip_snapshot = true
      publicly_accessible = false
      backup_retention = 5
      backup_window = "03:00-04:00"
      maintenance_window = "sun:04:00-sun:05:00"
    }
  }

  # Aurora設定
  aurora_configs = {
    main_aurora_postgres = {
      engine            = "aurora-postgresql"
      engine_version    = "14.9"
      cluster_name      = "${local.project_name}-aurora-postgres-${local.environment}"
      database_name     = "maindb"
      master_username   = "postgres"
      port             = 5432
      
      instances = {
        writer = {
          class = "db.r6g.medium" # dev用
          public = false
        }
        reader = null #dev用
      }
      
      backup_retention = 3 # dev用
      backup_window = "03:00-04:00"
      maintenance_window = "sun:04:00-sun:05:00"
      storage_encrypted = true
      deletion_protection = false # dev用
      skip_snapshot = true #dev用
      performance_insights = false # dev用
      monitoring_interval = 0 # dev用
      
      serverlessv2_scaling = {
        max_capacity = 4
        min_capacity = 0.5
      } # dev用
    }
  }

  # CORS設定
  cors_origins = [
    "https://dev.yourdomain.com",
    "http://localhost:3000"
  ]

  # ALB設定
  alb_config = {
    name = "${local.project_name}-alb-${local.environment}"
    internal = false
    enable_deletion_protection = false # dev用
    enable_access_logs = false # dev用
    
    target_groups = {
      backend = {
        name = "${local.project_name}-backend-tg-${local.environment}"
        port = 8080
        protocol = "HTTP"
        target_type = "ip"
        deregistration_delay = 30 # dev用
        
        health_check = {
          enabled = true
          healthy_threshold = 2
          unhealthy_threshold = 2
          timeout = 5
          interval = 30 # dev用
          path = local.app_config.health_path
          matcher = "200"
          protocol = "HTTP"
          port = "traffic-port"
        }
      }
      
      frontend = {
        name = "${local.project_name}-frontend-tg-${local.environment}"
        port = 3000
        protocol = "HTTP"
        target_type = "ip"
        deregistration_delay = 30 # dev用
        
        health_check = {
          enabled = true
          healthy_threshold = 2
          unhealthy_threshold = 2
          timeout = 5
          interval = 30
          path = "/"
          matcher = "200"
          protocol = "HTTP"
          port = "traffic-port"
        }
      }
    }
    
    listener_rules = {
      api = {
        priority = 100
        target_group = "backend"
        path_patterns = ["${/api}/*"]
      }
      health = {
        priority = 200
        target_group = "backend"
        path_patterns = ["/health", "/healthz"]
      }
      static = {
        priority = 300
        target_group = "frontend"
        path_patterns = ["/static/*", "/assets/*", "*.js", "*.css", "*.ico"]
      }
    }
    
    default_target_group = "frontend"
  }

  # 基本設定
  app_config = {
    name          = "my-awesome-app"
    version       = "1.0.0"
    backend_port  = 8080
    frontend_port = 3000
    api_prefix    = "/api"
    health_path   = "/health"
  }

  # 環境別設定(defaultはdev用)
  env_config = {
    # コンテナリソース
    backend_cpu    = 256
    backend_memory = 512
    frontend_cpu   = 256
    frontend_memory = 512
    
    # レプリカ数
    backend_replicas  = 1
    frontend_replicas = 1
    
    # その他
    log_level = "debug"
    enable_https = false
    enable_deletion_protection = false
  }

  # Amplifyアプリケーションの共通設定
  amplify_app = {
    app_name            = "my-awesome-amplify-app"
    repository_url      = "https://github.com/your-org/your-amplify-repo.git"
    branch_name         = "develop"
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
          baseDirectory: build
          files:
            - '**/*'
    EOT
    custom_rules = [
      {
        source = "/<*>"
        target = "/index.html"
        status = "200"
      }
    ]

    # 環境ごとの設定
    branch_stage = "DEVELOPMENT"
    environment_variables = {
      # 環境ごとの変数
      #VITE_API_URL = "https://${local.api_gateway_id}.execute-api.${local.aws_region}.amazonaws.com/prod"
    }
  }

  # cloudfront設定
  cloudfront_enabled_buckets = {
    # フロントエンド用
    frontend = {
      cache_behavior = {
        default_ttl = 86400      # 1日
        max_ttl     = 31536000   # 1年
        min_ttl     = 0
        compress    = true
      }
      origin_access_control_enabled = true
      default_root_object = "index.html"
      custom_error_responses = [
        {
          error_code         = 404
          response_code      = 200
          response_page_path = "/index.html"
          error_caching_min_ttl = 300
        },
        {
          error_code         = 403
          response_code      = 200
          response_page_path = "/index.html"
          error_caching_min_ttl = 300
        }
      ]
    }
    
    # プロフィール画像用（条件付き適用）
    profile_pictures = {
      cache_behavior = {
        default_ttl = 604800     # 1週間
        max_ttl     = 31536000   # 1年
        min_ttl     = 86400      # 1日
        compress    = true
      }
      origin_access_control_enabled = true
      default_root_object = null
      custom_error_responses = [
        {
          error_code         = 404
          response_code      = 404
          response_page_path = null
          error_caching_min_ttl = 300
        }
      ]
    }
  }
}



# Dev, Prod環境で共通のproviderとbackend設定を記述
# Provider設定を動的に生成
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = "${local.aws_region}"
}
EOF
}

# Terraform Cloud バックエンド設定
remote_state {
  backend = "remote"
  config = {
    organization = "sb-terraform"
    workspaces = {
      name = local.workspace_name
    }
  }
}