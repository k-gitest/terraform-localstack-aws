# コンピュート関連のlocals

locals {
  # ECRリポジトリ設定
  ecr_repositories = {
    backend = "${var.project_name}-backend"
    frontend = "${var.project_name}-frontend"
    image_processor = "${var.project_name}-image-processor"
  }

  # ECSクラスター設定
  ecs_cluster = {
    name = "${var.project_name}-cluster-${var.environment}"
    enable_fargate = true
    enable_container_insights = var.environment == "prod"
  }

  # Lambda設定
  lambda_functions = {
    image_processor = {
      name = "${var.project_name}-image-processor-${var.environment}"
      handler = "index.handler"
      runtime = "python3.11"
      timeout = var.environment == "prod" ? 300 : 60
      memory = var.environment == "prod" ? 1024 : 512
      
      environment = {
        ENVIRONMENT = var.environment
        LOG_LEVEL = local.env_config.log_level
        PROJECT = var.project_name
        MAX_IMAGE_SIZE = "10485760"
        ALLOWED_FORMATS = "jpg,jpeg,png,webp,gif"
        THUMBNAIL_SIZES = "150x150,300x300,600x600"
      }
    }
    
    auth_validator = {
      name = "${var.project_name}-auth-validator-${var.environment}"
      handler = "index.handler"
      runtime = "nodejs18.x"
      timeout = 30
      memory = 256
      
      environment = {
        ENVIRONMENT = var.environment
        LOG_LEVEL = local.env_config.log_level
        PROJECT = var.project_name
        TOKEN_EXPIRY = var.environment == "prod" ? "3600" : "86400"
      }
    }
  }

  # ALB設定
  alb_config = {
    name = "${var.project_name}-alb-${var.environment}"
    internal = false
    enable_deletion_protection = local.env_config.enable_deletion_protection
    enable_access_logs = var.environment == "prod"
    
    target_groups = {
      backend = {
        name = "${var.project_name}-backend-tg-${var.environment}"
        port = local.app_config.backend_port
        protocol = "HTTP"
        target_type = "ip"
        deregistration_delay = var.environment == "prod" ? 300 : 30
        
        health_check = {
          enabled = true
          healthy_threshold = local.env_config.backend_replicas >= 2 ? 3 : 2
          unhealthy_threshold = local.env_config.backend_replicas >= 2 ? 3 : 2
          timeout = 5
          interval = var.environment == "prod" ? 15 : 30
          path = local.app_config.health_path
          matcher = "200"
          protocol = "HTTP"
          port = "traffic-port"
        }
      }
      
      frontend = {
        name = "${var.project_name}-frontend-tg-${var.environment}"
        port = local.app_config.frontend_port
        protocol = "HTTP"
        target_type = "ip"
        deregistration_delay = var.environment == "prod" ? 300 : 30
        
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
        path_patterns = ["${local.app_config.api_prefix}/*"]
      }
      health = {
        priority = 200
        target_group = "backend"
        path_patterns = [local.app_config.health_path, "/healthz"]
      }
      static = {
        priority = 300
        target_group = "frontend"
        path_patterns = ["/static/*", "/assets/*", "*.js", "*.css", "*.ico"]
      }
    }
    
    default_target_group = "frontend"
  }

  # Auto Scaling設定
  auto_scaling = {
    backend = {
      min_capacity = var.environment == "prod" ? 2 : 1
      max_capacity = var.environment == "prod" ? 10 : 3
      
      cpu_scaling = {
        target_value = var.environment == "prod" ? 70 : 80
        scale_in_cooldown = 300
        scale_out_cooldown = 60
      }
      
      memory_scaling = {
        target_value = var.environment == "prod" ? 80 : 85
        scale_in_cooldown = 300
        scale_out_cooldown = 60
      }
      
      request_scaling = {
        target_value = var.environment == "prod" ? 1000 : 2000
        scale_in_cooldown = 300
        scale_out_cooldown = 60
      }
    }
    
    frontend = {
      min_capacity = 1
      max_capacity = var.environment == "prod" ? 5 : 2
      
      cpu_scaling = {
        target_value = 70
        scale_in_cooldown = 300
        scale_out_cooldown = 60
      }
      
      memory_scaling = {
        target_value = 80
        scale_in_cooldown = 300
        scale_out_cooldown = 60
      }
    }
  }

  # SNS設定
  sns_topics = var.environment == "prod" ? {
    "user-notifications" = {
      subscriptions = {
        email = {
          protocol = "email"
          endpoint = "admin@yourcompany.com"
        }
        lambda = {
          protocol = "lambda"
          endpoint = "arn:aws:lambda:${var.aws_region}:${var.aws_account_id}:function:${var.project_name}-notification-handler-${var.environment}"
        }
      }
      kms_key_arn = var.sns_kms_key_arn
      success_feedback_role_arn = var.sns_success_feedback_role_arn
      tags = {
        Purpose = "User notifications"
        Tier    = "critical"
      }
    }
  } : {
    # dev/local環境用の設定
    "user-notifications" = {
      subscriptions = {
        email = {
          protocol = "email"
          endpoint = "dev-team@yourcompany.com"
        }
      }
      tags = {
        Purpose = "User notifications"
        Tier    = "development"
      }
    }
  }

  # SQS設定
  sqs_queues = {
    "task-processing" = {
      is_fifo_queue              = false
      visibility_timeout_seconds = 60
      kms_key_arn               = var.environment == "prod" ? var.sqs_kms_key_arn : null
      dead_letter_queue_arn     = null
      max_receive_count         = 3
      tags = {
        Purpose = "Background task processing"
        Tier    = var.environment == "prod" ? "high" : "development"
      }
    }
  }

  # 環境変数設定
  backend_env_vars = [
    { name = "NODE_ENV", value = var.environment },
    { name = "APP_PORT", value = tostring(local.app_config.backend_port) },
    { name = "LOG_LEVEL", value = local.env_config.log_level },
    { name = "API_VERSION", value = "v1" },
    { name = "CORS_ORIGINS", value = join(",", local.cors_origins) },
    { name = "JWT_EXPIRES_IN", value = var.environment == "prod" ? "24h" : "7d" },
    { name = "RATE_LIMIT_WINDOW", value = "15" },
    { name = "RATE_LIMIT_MAX", value = var.environment == "prod" ? "100" : "1000" },
  ]

  frontend_env_vars = [
    { name = "NODE_ENV", value = var.environment },
    { name = "REACT_APP_ENV", value = var.environment },
    { name = "REACT_APP_VERSION", value = local.app_config.version },
    { name = "REACT_APP_TITLE", value = local.app_config.name },
  ]

  # シークレット設定
  backend_secrets = var.environment == "local" ? [] : [
    {
      name = "DB_PASSWORD"
      valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current[0].account_id}:parameter/${var.project_name}/${var.environment}/db-password"
    },
    {
      name = "JWT_SECRET"
      valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current[0].account_id}:parameter/${var.project_name}/${var.environment}/jwt-secret"
    }
  ]
}