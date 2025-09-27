variable "topic_name" {
  description = "作成するSNSトピックの名前"
  type        = string
}

variable "subscriptions" {
  description = "トピックに作成するサブスクリプションのマップ"
  type = map(object({
    protocol = string
    endpoint = string
  }))
  default = {}
}

variable "kms_key_arn" {
  description = "暗号化に使用するKMSキーのARN"
  type        = string
  default     = null
}

variable "success_feedback_role_arn" {
  description = "成功フィードバック用のIAMロールのARN"
  type        = string
  default     = null
}

variable "tags" {
  description = "SNSトピックに割り当てるタグのマップ"
  type        = map(string)
  default     = {}
}