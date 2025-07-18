# S3からLambdaを呼び出す権限
resource "aws_lambda_permission" "allow_s3_to_invoke_lambda" {
  statement_id  = var.statement_id != null ? var.statement_id : "AllowExecutionFromS3-${var.s3_bucket_name}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.s3_bucket_arn
}

# S3イベント通知の設定
resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = var.s3_bucket_id

  lambda_function {
    lambda_function_arn = var.lambda_function_arn
    events              = var.lambda_events
    filter_prefix       = var.lambda_filter_prefix
    filter_suffix       = var.lambda_filter_suffix
  }

  depends_on = [aws_lambda_permission.allow_s3_to_invoke_lambda]
}