# Dev, Prod環境で共通のproviderとbackend設定を記述

# 現在の環境名を取得
# 例: live/dev/ec2 で実行すると "dev" が取得される
/*
locals {
  environment = basename(dirname(path_relative_to_include()))
  Project     = var.project_name
  ManagedBy   = "terraform"
  Owner       = "DevOps"
  CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
}
*/

locals {
  project_name = "my-awesome-project"

  # "dev/foundation/network" → "dev"
  relative_path = path_relative_to_include()
  environment   = split("/", local.relative_path)[0]
  segment       = length(local.path_parts) > 1 ? local.path_parts[1] : null  # "foundation"
  service       = length(local.path_parts) > 2 ? local.path_parts[2] : null  # "network"

  # workspace名の設定
  workspace_name = join("-", compact([
    "mock-terraform",
    local.environment,
    local.segment,
    local.service
  ]))

  module_root = "${get_repo_root()}/terraform/modules"

  common_tags = {
    Project   = local.project_name
    ManagedBy = "terragrunt"
    Owner     = "DevOps"
    CreatedAt = formatdate("YYYY-MM-DD", timestamp())
    Env       = local.environment
  }
}


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