# s3のモジュール呼び出し
module "my_s3_bucket" {
  source = "./modules/s3" # modules/s3 ディレクトリを参照
  
  bucket_name = "my-awesome-localstack-bucket-12345"
  #acl         = "private"
  tags = {
    Environment = "LocalStack"
    Project     = "TerraformTest"
  }
  upload_example_object = true
  block_public_access   = true
}