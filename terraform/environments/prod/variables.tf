variable "aws_region" {
  description = "The AWS region to deploy resources to."
  type        = string
  default     = "ap-northeast-1"
}

variable "container_image" {
  description = "Complete Docker image URI including tag"
  type        = string
  default     = null
}