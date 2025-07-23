# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  # Container Insights setting
  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  # Execute command configuration
  dynamic "configuration" {
    for_each = var.enable_execute_command_logging ? [1] : []
    content {
      execute_command_configuration {
        kms_key_id = null # Use default AWS managed key
        
        dynamic "log_configuration" {
          for_each = var.execute_command_log_group_name != "" || var.execute_command_s3_bucket_name != "" ? [1] : []
          content {
            cloud_watch_encryption_enabled = false
            cloud_watch_log_group_name     = var.execute_command_log_group_name != "" ? var.execute_command_log_group_name : null
            
            s3_bucket_name                 = var.execute_command_s3_bucket_name != "" ? var.execute_command_s3_bucket_name : null
            s3_key_prefix                  = var.execute_command_s3_bucket_name != "" ? var.execute_command_s3_key_prefix : null
          }
        }
        
        logging = var.execute_command_log_group_name != "" || var.execute_command_s3_bucket_name != "" ? "OVERRIDE" : "DEFAULT"
      }
    }
  }

  tags = merge(var.tags, {
    Name        = var.cluster_name
    Environment = var.environment
    Project     = var.project_name
  })
}

# Capacity Providers
locals {
  capacity_providers = concat(
    var.enable_fargate ? ["FARGATE"] : [],
    var.enable_fargate_spot ? ["FARGATE_SPOT"] : [],
    var.enable_ec2 ? ["EC2"] : []
  )
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = local.capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy
    content {
      base              = default_capacity_provider_strategy.value.base
      weight            = default_capacity_provider_strategy.value.weight
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
    }
  }
}

# CloudWatch Log Group for Execute Command (if needed)
resource "aws_cloudwatch_log_group" "execute_command" {
  count = var.enable_execute_command_logging && var.execute_command_log_group_name != "" ? 1 : 0
  
  name              = var.execute_command_log_group_name
  retention_in_days = 30

  tags = merge(var.tags, {
    Name        = var.execute_command_log_group_name
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "ecs-execute-command"
  })
}