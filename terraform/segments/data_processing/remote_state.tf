data "terraform_remote_state" "application" {
  backend = "s3"
  config = {
    bucket = "your-terraform-state-bucket"
    key    = "application/terraform.tfstate"
    region = "ap-northeast-1"

    endpoints = {
      s3 = "http://localhost:4566"
    }

    access_key = "test"
    secret_key = "test"
    skip_credentials_validation = true
    skip_metadata_api_check = true
    use_path_style = true
    skip_requesting_account_id = true
  }
}