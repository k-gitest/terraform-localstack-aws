variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alb_name" {
  description = "Name of the ALB"
  type        = string
}

variable "internal" {
  description = "Whether the load balancer is internal or external"
  type        = bool
  default     = false
}

variable "subnets" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "security_groups" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "target_groups" {
  description = "Map of target groups"
  type = map(object({
    name     = string
    port     = number
    protocol = string
    health_check = object({
      enabled             = bool
      healthy_threshold   = number
      interval            = number
      matcher             = string
      path                = string
      protocol            = string
      port                = string
      timeout             = number
      unhealthy_threshold = number
    })
  }))
  default = {}
}

variable "default_target_group" {
  description = "Default target group key"
  type        = string
  default     = ""
}

variable "listener_rules" {
  description = "Map of listener rules"
  type = map(object({
    priority      = number
    target_group  = string
    path_patterns = list(string)
  }))
  default = {}
}

variable "enable_https" {
  description = "Enable HTTPS listener"
  type        = bool
  default     = false
}

variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}