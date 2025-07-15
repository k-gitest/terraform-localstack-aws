variable "aws_region" {
  description = "The AWS region to deploy resources to."
  type        = string
  default     = "us-east-1" # LocalStack で一般的に使用されるリージョン
}