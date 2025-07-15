terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # または "> 5.0"
    }
  }
}

provider "aws" {
  region                      = var.aws_region
  access_key                  = "test"
  secret_key                  = "test"
  #s3_force_path_style         = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  endpoints {
    s3          = "http://localhost:4566"
  }
}
