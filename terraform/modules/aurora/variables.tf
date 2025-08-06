variable "project_name" {
  description = "プロジェクト名"
  type        = string
}

variable "environment" {
  description = "環境名（dev, staging, prod など）"
  type        = string
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
  description = "Auroraへのアクセスを許可するアプリケーション（ECS等）のセキュリティグループID"
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

variable "db_subnet_group_name" {
  description = "Aurora クラスター用のDBサブネットグループ名"
  type        = string
}

variable "database_security_group_id" {
  description = "databaseのセキュリティグループ ID"
  type        = string
}

variable "tags" {
  description = "リソースに適用するタグのマップ"
  type        = map(string)
  default     = {}
}