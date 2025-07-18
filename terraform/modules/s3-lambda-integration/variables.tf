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

# 複数のフィルター条件（高度な設定）
variable "lambda_filters" {
  description = "複数のフィルター条件"
  type = list(object({
    prefix = optional(string)
    suffix = optional(string)
  }))
  default = []
}

# 権限設定
variable "statement_id" {
  description = "Lambda権限のステートメントID"
  type        = string
  default     = null
}

variable "source_account" {
  description = "S3バケットのアカウントID（セキュリティ強化）"
  type        = string
  default     = null
}

# 通知設定の有効化フラグ
variable "enable_notification" {
  description = "S3イベント通知を有効にするかどうか"
  type        = bool
  default     = true
}

# 複数Lambda関数への通知設定
variable "lambda_configurations" {
  description = "複数のLambda関数への通知設定"
  type = list(object({
    lambda_function_arn = string
    events              = list(string)
    filter_prefix       = optional(string)
    filter_suffix       = optional(string)
    id                  = optional(string)
  }))
  default = []
}

# その他の通知設定（SNS、SQS）
variable "topic_configurations" {
  description = "SNSトピックへの通知設定"
  type = list(object({
    topic_arn     = string
    events        = list(string)
    filter_prefix = optional(string)
    filter_suffix = optional(string)
    id            = optional(string)
  }))
  default = []
}

variable "queue_configurations" {
  description = "SQSキューへの通知設定"
  type = list(object({
    queue_arn     = string
    events        = list(string)
    filter_prefix = optional(string)
    filter_suffix = optional(string)
    id            = optional(string)
  }))
  default = []
}