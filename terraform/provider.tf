terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # または "> 5.0"
    }
  }

  /* Local開発時はこの部分をコメントアウト
  cloud { 
    organization = "sb-terraform" 
    workspaces { 
      name = "mock_terraform" 
    } 
  }
  */
}


provider "aws" {
  region                      = var.aws_region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  s3_use_path_style = true

  # localワークスペースの場合のみエンドポイントを設定
  dynamic "endpoints" {
    for_each = terraform.workspace == "local" ? ["local"] : []
    content {
      s3       = "http://localhost:4566"
      iam      = "http://localhost:4566"
      lambda   = "http://localhost:4566"
      dynamodb = "http://localhost:4566"
      sqs      = "http://localhost:4566"
      sns      = "http://localhost:4566"
      ecr      = "http://localhost:4566"
      ecs      = "http://localhost:4566"
    }
  }

}

# 現在のAWSアカウントIDとリージョンを取得するデータソース
 data "aws_caller_identity" "current" {}
# data "aws_region" "current" {}
