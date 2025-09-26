variable "topic_name" {
  description = "The name of the SNS topic to create."
  type        = string
}

variable "subscriptions" {
  description = "A map of subscriptions to create for the topic. Keys are subscription IDs, values are objects with protocol and endpoint."
  type        = map(object({
    protocol = string
    endpoint = string
  }))
  default     = {}
}

variable "tags" {
  description = "A map of tags to assign to the SNS topic."
  type        = map(string)
  default     = {}
}