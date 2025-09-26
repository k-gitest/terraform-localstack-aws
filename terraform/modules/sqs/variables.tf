variable "queue_name" {
  description = "The name of the SQS queue."
  type        = string
}

variable "is_fifo_queue" {
  description = "Whether to create a FIFO queue."
  type        = bool
  default     = false
}