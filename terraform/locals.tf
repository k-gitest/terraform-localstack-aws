# 全体で使用するlocals定義

locals {
  # 共通タグ
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Owner       = "DevOps"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
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

  # 環境別設定
  env_config = {
    # コンテナリソース
    backend_cpu    = var.environment == "prod" ? 1024 : 256
    backend_memory = var.environment == "prod" ? 2048 : 512
    frontend_cpu   = var.environment == "prod" ? 512 : 256
    frontend_memory = var.environment == "prod" ? 1024 : 512
    
    # レプリカ数
    backend_replicas  = var.environment == "prod" ? 3 : 1
    frontend_replicas = var.environment == "prod" ? 2 : 1
    
    # その他
    log_level = var.environment == "prod" ? "info" : "debug"
    enable_https = var.environment == "prod"
    enable_deletion_protection = var.environment == "prod"
  }

  # ネットワーク設定
  network_config = {
    vpc_cidr = var.environment == "prod" ? "10.0.0.0/16" : "10.1.0.0/16"
    
    public_subnet_cidrs = var.environment == "prod" ? [
      "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"
    ] : [
      "10.1.1.0/24", "10.1.2.0/24"
    ]
    
    private_subnet_cidrs = var.environment == "prod" ? [
      "10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"
    ] : [
      "10.1.10.0/24", "10.1.20.0/24"
    ]
  }

  # CORS設定
  cors_origins = var.environment == "prod" ? [
    "https://yourdomain.com",
    "https://www.yourdomain.com"
  ] : var.environment == "dev" ? [
    "https://dev.yourdomain.com",
    "http://localhost:3000"
  ] : [
    "http://localhost:3000",
    "http://127.0.0.1:3000"
  ]
}