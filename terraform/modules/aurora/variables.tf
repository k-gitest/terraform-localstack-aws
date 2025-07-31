variable "project_name" {
  description = "プロジェクト名"
  type        = string
}

variable "environment" {
  description = "環境名（dev, staging, prod など）"
  type        = string
}

variable "aurora_configs" {
  description = "Auroraクラスターの設定マップ"
  type = map(object({
    engine                = string
    engine_version        = string
    cluster_identifier    = string
    database_name         = string
    master_username       = string
    master_password       = string
    port                  = number
    
    # インスタンス設定
    instances = map(object({
      instance_class      = string
      publicly_accessible = bool
    }))
    
    # バックアップ設定
    backup_retention_period      = number
    preferred_backup_window      = string
    preferred_maintenance_window = string
    
    # セキュリティ設定
    storage_encrypted         = bool
    deletion_protection       = bool
    skip_final_snapshot       = bool
    final_snapshot_identifier = optional(string)
    
    # パフォーマンス設定
    performance_insights_enabled = bool
    monitoring_interval          = number
    #auto_minor_version_upgrade   = bool
    
    # サーバーレスv2設定（オプション）
    serverlessv2_scaling_configuration = optional(object({
      max_capacity = number
      min_capacity = number
    }))
    
    # パラメータグループ設定
    cluster_parameter_group_family = string
    db_parameter_group_family      = string
    custom_cluster_parameters      = map(string)
    custom_db_parameters          = map(string)
  }))
  
  validation {
    condition = alltrue([
      for config in values(var.aurora_configs) : 
      contains(["aurora-postgresql", "aurora-mysql"], config.engine)
    ])
    error_message = "サポートされているエンジンは 'aurora-postgresql' または 'aurora-mysql' です。"
  }
  
  validation {
    condition = alltrue([
      for config in values(var.aurora_configs) : 
      config.backup_retention_period >= 1 && config.backup_retention_period <= 35
    ])
    error_message = "backup_retention_period は 1 から 35 の間で設定してください。"
  }
  
  validation {
    condition = alltrue([
      for config in values(var.aurora_configs) : 
      config.monitoring_interval == 0 || contains([1, 5, 10, 15, 30, 60], config.monitoring_interval)
    ])
    error_message = "monitoring_interval は 0, 1, 5, 10, 15, 30, 60 のいずれかを設定してください。"
  }
}

variable "vpc_id" {
  description = "Aurora クラスターを配置する VPC の ID"
  type        = string
}

variable "db_subnet_ids" {
  description = "Aurora クラスター用のサブネット ID のリスト（最低2つのAZが必要）"
  type        = list(string)
  
  validation {
    condition     = length(var.db_subnet_ids) >= 2
    error_message = "Aurora クラスターには最低2つのサブネットが必要です。"
  }
}

variable "application_security_group_id" {
  description = "Aurora へのアクセスを許可するアプリケーション（ECS等）のセキュリティグループ ID"
  type        = string
}

variable "tags" {
  description = "リソースに適用するタグのマップ"
  type        = map(string)
  default     = {}
}

# 追加のオプション設定
variable "enable_deletion_protection" {
  description = "削除保護を有効にするかどうか（環境によって上書き可能）"
  type        = bool
  default     = false
}

variable "kms_key_deletion_window" {
  description = "KMS キーの削除待機期間（日数）"
  type        = number
  default     = 7
  
  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "KMS キーの削除待機期間は 7 から 30 日の間で設定してください。"
  }
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch ログの保持期間（日数）"
  type        = number
  default     = 7
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.cloudwatch_log_retention_days)
    error_message = "無効なログ保持期間です。AWS で許可されている値を指定してください。"
  }
}

variable "performance_insights_retention_period" {
  description = "Performance Insights のデータ保持期間（日数）"
  type        = number
  default     = 7
  
  validation {
    condition = var.performance_insights_retention_period == 7 || (
      var.performance_insights_retention_period >= 31 && 
      var.performance_insights_retention_period <= 731
    )
    error_message = "Performance Insights の保持期間は 7 日、または 31-731 日の間で設定してください。"
  }
}

variable "enable_http_endpoint" {
  description = "Data API（HTTP エンドポイント）を有効にするかどうか"
  type        = bool
  default     = false
}

variable "backup_window" {
  description = "デフォルトのバックアップウィンドウ（UTC）"
  type        = string
  default     = "03:00-04:00"
  
  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]-([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.backup_window))
    error_message = "バックアップウィンドウは HH:MM-HH:MM 形式で指定してください（例: 03:00-04:00）。"
  }
}

variable "maintenance_window" {
  description = "デフォルトのメンテナンスウィンドウ"
  type        = string
  default     = "sun:04:00-sun:05:00"
  
  validation {
    condition = can(regex("^(sun|mon|tue|wed|thu|fri|sat):[0-2][0-9]:[0-5][0-9]-(sun|mon|tue|wed|thu|fri|sat):[0-2][0-9]:[0-5][0-9]$", var.maintenance_window))
    error_message = "メンテナンスウィンドウは ddd:hh:mm-ddd:hh:mm 形式で指定してください（例: sun:04:00-sun:05:00）。"
  }
}