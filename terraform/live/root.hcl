# 共通変数の設定
locals {
  project_name = "my-awesome-project"

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

  # データベースの共通デフォルト値を定義
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
  region = "ap-northeast-1"
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