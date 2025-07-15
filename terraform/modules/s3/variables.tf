variable "bucket_name" {
  description = "The name of the S3 bucket to create."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}

variable "upload_example_object" {
  description = "Whether to upload an example object to the bucket."
  type        = bool
  default     = false
}

variable "block_public_access" {
  description = "Whether to block all public access to the S3 bucket."
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "バケットのバージョニングを有効にするかどうか"
  type        = bool
  default     = false
}

variable "enable_encryption" {
  description = "バケットの暗号化を有効にするかどうか"
  type        = bool
  default     = true
}