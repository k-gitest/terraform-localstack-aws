# ECS Service Configuration
variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "desired_count" {
  description = "Number of instances of the task definition to place and keep running"
  type        = number
  default     = 1
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging"
  type        = bool
  default     = false
}

# Task Definition Configuration
variable "task_family" {
  description = "Family name for the task definition"
  type        = string
  default     = ""
}

variable "cpu" {
  description = "Number of CPU units used by the task"
  type        = number
  default     = 256
  
  validation {
    condition = contains([256, 512, 1024, 2048, 4096, 8192, 16384], var.cpu)
    error_message = "CPU must be one of: 256, 512, 1024, 2048, 4096, 8192, 16384."
  }
}

variable "memory" {
  description = "Amount of memory (in MiB) used by the task"
  type        = number
  default     = 512
  
  validation {
    condition = var.memory >= 512 && var.memory <= 30720
    error_message = "Memory must be between 512 and 30720 MiB."
  }
}

# Container Configuration
variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = ""
}

variable "container_image" {
  description = "Docker image to use for the container"
  type        = string
}

variable "container_port" {
  description = "Port on which the container listens"
  type        = number
  default     = 80
}

variable "container_protocol" {
  description = "Protocol used by the container"
  type        = string
  default     = "tcp"
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "secrets" {
  description = "Secrets from AWS Systems Manager Parameter Store or AWS Secrets Manager"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "container_command" {
  description = "Command to run in the container"
  type        = list(string)
  default     = null
}

variable "container_entry_point" {
  description = "Entry point for the container"
  type        = list(string)
  default     = null
}

# Networking Configuration
variable "subnets" {
  description = "List of subnet IDs for the service"
  type        = list(string)
}

variable "security_groups" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign a public IP address to the ENI"
  type        = bool
  default     = false
}

# Load Balancer Configuration
variable "enable_load_balancer" {
  description = "Enable load balancer integration"
  type        = bool
  default     = false
}

variable "target_group_arn" {
  description = "ARN of the load balancer target group"
  type        = string
  default     = ""
}

variable "load_balancer_container_name" {
  description = "Name of the container to associate with the load balancer"
  type        = string
  default     = ""
}

variable "load_balancer_container_port" {
  description = "Port on the container to associate with the load balancer"
  type        = number
  default     = 80
}

# Auto Scaling Configuration
variable "enable_autoscaling" {
  description = "Enable auto scaling for the service"
  type        = bool
  default     = false
}

variable "min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 10
}

variable "target_cpu_utilization" {
  description = "Target CPU utilization for auto scaling"
  type        = number
  default     = 70
}

variable "target_memory_utilization" {
  description = "Target memory utilization for auto scaling"
  type        = number
  default     = 80
}

# Logging Configuration
variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
  default     = ""
}

variable "log_retention_in_days" {
  description = "Log retention period in days"
  type        = number
  default     = 30
}

variable "log_stream_prefix" {
  description = "Log stream prefix"
  type        = string
  default     = "ecs"
}

# Health Check Configuration
variable "health_check_grace_period_seconds" {
  description = "Grace period for health checks (when using load balancer)"
  type        = number
  default     = 60
}

# Deployment Configuration
variable "deployment_maximum_percent" {
  description = "Upper limit on the number of running tasks during deployment"
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "Lower limit on the number of running tasks during deployment"
  type        = number
  default     = 50
}

variable "enable_deployment_circuit_breaker" {
  description = "Enable deployment circuit breaker"
  type        = bool
  default     = true
}

variable "deployment_circuit_breaker_rollback" {
  description = "Enable rollback on deployment circuit breaker failure"
  type        = bool
  default     = true
}

# Service Discovery Configuration
variable "enable_service_discovery" {
  description = "Enable service discovery"
  type        = bool
  default     = false
}

variable "service_discovery_namespace_id" {
  description = "Service discovery namespace ID"
  type        = string
  default     = ""
}

variable "service_discovery_service_name" {
  description = "Service discovery service name"
  type        = string
  default     = ""
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