terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  cloud { 
    organization = "sb-terraform" 
    workspaces { 
      name = "mock_terraform_dev" 
    } 
  }
}


provider "aws" {
  region                      = var.aws_region
}

# 現在のAWSアカウントIDとリージョンを取得するデータソース
 data "aws_caller_identity" "current" {}
 data "aws_region" "current" {}
