# Dev, Prod環境で共通のproviderとbackend設定を記述

# 現在の環境名を取得
# 例: live/dev/ec2 で実行すると "dev" が取得される
locals {
  environment = basename(dirname(path_relative_to_include()))
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
      name = "mock_terraform_${local.environment}"
    }
  }
}