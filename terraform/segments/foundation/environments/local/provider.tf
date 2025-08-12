terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # または "> 5.0"
    }
  }

  backend "s3" {
    bucket                      = "your-terraform-state-bucket"
    key                         = "foundation/terraform.tfstate"
    region                      = "ap-northeast-1"
    endpoint                    = "http://localhost:4566"
    access_key                  = "test"
    secret_key                  = "test"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    use_path_style            = true
    skip_requesting_account_id  = true
  }
}


provider "aws" {
  region                      = var.aws_region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  s3_use_path_style = true

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

# 現在のAWSアカウントIDとリージョンを取得するデータソース
 #data "aws_caller_identity" "current" {}
 #data "aws_region" "current" {}