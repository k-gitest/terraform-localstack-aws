# Lambda関数
module "image_processor_lambda" {
  source = "../../modules/lambda"
  
  function_name = local.lambda_functions.image_processor.name
  lambda_zip_file = "${path.module}/image_processor.zip"
  handler = local.lambda_functions.image_processor.handler
  runtime = local.lambda_functions.image_processor.runtime
  timeout = local.lambda_functions.image_processor.timeout
  memory_size = local.lambda_functions.image_processor.memory
  
  environment_variables = local.lambda_functions.image_processor.environment
  
  s3_bucket_arns = [
    for bucket in local.lambda_functions.image_processor.user_content_s3_buckets : bucket.bucket_arn
  ]
  
  tags = local.common_tags
}

# SNSモジュール
module "sns" {
  source = "./modules/sns"
  count  = var.create_sns ? 1 : 0

  topic_name = "${local.prefix}-my-topic"
  subscriptions = {
    # Lambdaと連携する場合
    lambda = {
      protocol = "lambda"
      endpoint = "arn:aws:lambda:${var.aws_region}:${var.aws_account_id}:function:my-function"
    }
  }
  tags       = local.default_tags
}

# SQSモジュール
module "sqs" {
  source = "./modules/sqs"
  count  = var.create_sqs ? 1 : 0

  queue_name = "${local.prefix}-my-queue"
  is_fifo_queue = false
  tags       = local.default_tags
}

# データソース
data "aws_region" "current" {}
data "aws_caller_identity" "current" {
  count = var.environment == "local" ? 0 : 1
}