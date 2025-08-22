# Local環境共通設定

include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  aws_region = include.local.aws_region
}

# ルートのterragrunt.hclから`locals`ブロックのみを読み込む場合
# `path_relative_from_dir()` を使ってルートファイルのパスを取得
/*
locals {
  environment = "local"

  root_config = read_terragrunt_config(find_in_parent_folders())
  project_name = local.root_config.locals.project_name
  aws_region = local.root_config.locals.aws_region
  database_configs = local.root_config.locals.database_configs
}
*/

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
  region                      = "${local.aws_region}"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3       = "http://localhost:4566"
    iam      = "http://localhost:4566"
    lambda   = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    sqs      = "http://localhost:4566"
    sns      = "http://localhost:4566"
    ecr      = "http://localhost:4566"
    ecs      = "http://localhost:4566"
    ec2      = "http://localhost:4566"
  }
}
EOF
}

remote_state {
  backend = "s3"
  config = {
    bucket                      = "terraform-state-local"
    key                         = "${path_relative_from_dir()}/terraform.tfstate"
    region                      = "${local.aws_region}"
    endpoint                    = "http://localhost:4566"
    access_key                  = "test"
    secret_key                  = "test"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    force_path_style            = true
  }
}
