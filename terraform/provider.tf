terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # または "> 5.0"
    }
  }

/*
  cloud { 
    organization = "sb-terraform" 
    workspaces { 
      name = "mock_terraform" 
    } 
  }
  */
}

/*
provider "aws" {
  region                      = var.aws_region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  endpoints {
    s3 = {
      url                 = "http://localhost:4566"
      s3_force_path_style = true
    }
    iam    = "http://localhost:4566"
    lambda = "http://localhost:4566"
  }

}
  */