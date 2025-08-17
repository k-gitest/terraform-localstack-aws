locals {
  environment = "prod"
}

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
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
EOF
}

remote_state {
  backend = "remote"
  config = {
    organization = "sb-terraform"
    workspaces = {
      name = "mock_terraform_prod"
    }
  }
}
