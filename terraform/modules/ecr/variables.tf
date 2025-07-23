# ECR Repository Configuration
variable "repository_name" { # 必須
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"
  
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

# Lifecycle Policy Configuration
variable "enable_lifecycle_policy" {
  description = "Enable lifecycle policy for the ECR repository"
  type        = bool
  default     = true
}

variable "untagged_image_expiry_days" {
  description = "Number of days to retain untagged images"
  type        = number
  default     = 1
}

variable "tagged_image_count_limit" {
  description = "Number of tagged images to retain"
  type        = number
  default     = 10
}

# Repository Policy Configuration
variable "enable_cross_account_access" {
  description = "Enable cross-account access to the ECR repository"
  type        = bool
  default     = false
}

variable "allowed_account_ids" {
  description = "List of AWS account IDs allowed to access this repository"
  type        = list(string)
  default     = []
}

# Tagging
variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default = {
    Terraform = "true"
  }
}

# Common naming convention
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "myapp"
}