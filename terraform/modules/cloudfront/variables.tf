variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "bucket_type" {
  description = "Type of bucket (frontend, profile_pictures, user_documents, etc.)"
  type        = string
  default     = "frontend"
}

variable "s3_bucket_domain_name" {
  description = "The domain name of the S3 bucket to serve as the origin."
  type        = string
}

variable "default_root_object" {
  description = "The object that CloudFront returns when a viewer requests the root URL."
  type        = string
  default     = "index.html"
}

variable "origin_access_control_enabled" {
  description = "Enable Origin Access Control (OAC)"
  type        = bool
  default     = true
}

variable "default_cache_behavior" {
  description = "Default cache behavior settings"
  type = object({
    default_ttl = optional(number, 86400)
    max_ttl     = optional(number, 31536000)
    min_ttl     = optional(number, 0)
    compress    = optional(bool, true)
  })
  default = {
    default_ttl = 86400
    max_ttl     = 31536000
    min_ttl     = 0
    compress    = true
  }
}

variable "custom_error_responses" {
  description = "Custom error response configuration"
  type = list(object({
    error_code            = number
    response_code         = optional(number)
    response_page_path    = optional(string)
    error_caching_min_ttl = optional(number)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}