# ECSクラスター設定
variable "cluster_name" { #（必須）
  description = "ECSクラスターの名前"
  type        = string
}

# キャパシティプロバイダー設定
variable "enable_fargate" {
  description = "Fargateキャパシティプロバイダーを有効にする"
  type        = bool
  default     = true
}

variable "enable_fargate_spot" {
  description = "Fargate Spotキャパシティプロバイダーを有効にする"
  type        = bool
  default     = false
}

variable "enable_ec2" {
  description = "EC2キャパシティプロバイダーを有効にする（ECSエージェント付きのEC2インスタンスが必要）"
  type        = bool
  default     = false
}

variable "default_capacity_provider_strategy" {
  description = "クラスターのデフォルトキャパシティプロバイダー戦略"
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

# Container Insights設定
variable "enable_container_insights" {
  description = "クラスターのCloudWatch Container Insightsを有効にする"
  type        = bool
  default     = true
}

# Execute Command設定
variable "enable_execute_command_logging" {
  description = "ECS execute commandのログ記録を有効にする"
  type        = bool
  default     = false
}

variable "execute_command_log_group_name" {
  description = "execute commandログ記録用のCloudWatchロググループ名"
  type        = string
  default     = ""
}

variable "execute_command_s3_bucket_name" {
  description = "execute commandログ記録用のS3バケット名"
  type        = string
  default     = ""
}

variable "execute_command_s3_key_prefix" {
  description = "execute commandログ記録用のS3キープレフィックス"
  type        = string
  default     = "ecs-execute-command"
}

# タグ設定
variable "tags" {
  description = "リソースに割り当てるタグのマップ"
  type        = map(string)
  default = {
    Terraform = "true"
  }
}

# 共通命名規則
variable "environment" {
  description = "環境名（例：dev、staging、prod）"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "myapp"
}