# Lambda関数の基本設定
variable "function_name" {
  description = "Lambda関数の名前"
  type        = string
}

variable "lambda_zip_file" {
  description = "Lambda関数のZIPファイルパス"
  type        = string
}

variable "handler" {
  description = "Lambda関数のハンドラー"
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Lambda関数のランタイム"
  type        = string
  default     = "python3.9"
}

variable "timeout" {
  description = "Lambda関数のタイムアウト（秒）"
  type        = number
  default     = 300
}

variable "memory_size" {
  description = "Lambda関数のメモリサイズ（MB）"
  type        = number
  default     = 128
}

# 環境変数
variable "environment_variables" {
  description = "Lambda関数の環境変数"
  type        = map(string)
  default     = {}
}

# S3アクセス権限
variable "s3_bucket_arns" {
  description = "LambdaがアクセスするS3バケットのARNリスト"
  type        = list(string)
  default     = []
}

# 追加のIAMポリシー
variable "additional_policy_arns" {
  description = "Lambda関数に追加するIAMポリシーのARNリスト"
  type        = list(string)
  default     = []
}

variable "custom_policies" {
  description = "カスタムIAMポリシーの定義"
  type = list(object({
    name   = string
    policy = string
  }))
  default = []
}

# VPC設定（必要に応じて）
variable "vpc_config" {
  description = "Lambda関数のVPC設定"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

# タグ
variable "tags" {
  description = "Lambda関数に付与するタグ"
  type        = map(string)
  default     = {}
}

# デッドレターキュー設定
variable "dead_letter_config" {
  description = "デッドレターキューの設定"
  type = object({
    target_arn = string
  })
  default = null
}

# 予約済み同時実行数
variable "reserved_concurrent_executions" {
  description = "予約済み同時実行数"
  type        = number
  default     = -1
}