# ECS Cluster Configuration
variable "cluster_name" { #（必須）
  description = "Name of the ECS cluster"
  type        = string
}

# Capacity Providers Configuration
variable "enable_fargate" {
  description = "Enable Fargate capacity provider"
  type        = bool
  default     = true
}

variable "enable_fargate_spot" {
  description = "Enable Fargate Spot capacity provider"
  type        = bool
  default     = false
}

variable "enable_ec2" {
  description = "Enable EC2 capacity provider (requires EC2 instances with ECS agent)"
  type        = bool
  default     = false
}

variable "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy for the cluster"
  type = list(object({
    capacity_provider = string
    weight           = number
    base            = optional(number, 0)
  }))
  default = [
    {
      capacity_provider = "FARGATE"
      weight           = 100
      base            = 0
    }
  ]
}

# Container Insights Configuration
variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = true
}

# Execute Command Configuration
variable "enable_execute_command_logging" {
  description = "Enable logging for ECS execute command"
  type        = bool
  default     = false
}

variable "execute_command_log_group_name" {
  description = "CloudWatch log group name for execute command logging"
  type        = string
  default     = ""
}

variable "execute_command_s3_bucket_name" {
  description = "S3 bucket name for execute command logging"
  type        = string
  default     = ""
}

variable "execute_command_s3_key_prefix" {
  description = "S3 key prefix for execute command logging"
  type        = string
  default     = "ecs-execute-command"
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