variable "queue_name" {
  description = "SQSキューの名前"
  type        = string
}

variable "is_fifo_queue" {
  description = "FIFOキューを作成するかどうか"
  type        = bool
  default     = false
}

variable "visibility_timeout_seconds" {
  description = "キューの可視性タイムアウト（秒）"
  type        = number
  default     = 30
}

variable "kms_key_arn" {
  description = "暗号化に使用するKMSキーのARN"
  type        = string
  default     = null
}

variable "dead_letter_queue_arn" {
  description = "デッドレターキューのARN"
  type        = string
  default     = null
}

variable "max_receive_count" {
  description = "デッドレターキューに送信する前の最大受信回数"
  type        = number
  default     = 3
}

variable "tags" {
  description = "SQSキューに割り当てるタグのマップ"
  type        = map(string)
  default     = {}
}