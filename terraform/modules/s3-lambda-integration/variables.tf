# S3バケット情報
variable "s3_bucket_id" {
  description = "S3バケットのID"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3バケットのARN"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3バケットの名前（権限設定用）"
  type        = string
}

# Lambda関数情報
variable "lambda_function_arn" {
  description = "Lambda関数のARN"
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda関数の名前"
  type        = string
}

# S3イベント設定
variable "lambda_events" {
  description = "S3イベントのタイプリスト"
  type        = list(string)
  default     = ["s3:ObjectCreated:*"]
}

variable "lambda_filter_prefix" {
  description = "S3イベントのフィルタープレフィックス"
  type        = string
  default     = null
}

variable "lambda_filter_suffix" {
  description = "S3イベントのフィルターサフィックス"
  type        = string
  default     = null
}

# 権限設定
variable "statement_id" {
  description = "Lambda権限のステートメントID"
  type        = string
  default     = null
}