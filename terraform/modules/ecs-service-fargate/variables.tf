# ECSサービス設定
variable "service_name" {
  description = "ECSサービスの名前"
  type        = string
}

variable "cluster_name" {
  description = "ECSクラスターの名前"
  type        = string
}

variable "desired_count" {
  description = "実行し続けるタスク定義のインスタンス数"
  type        = number
  default     = 1
}

variable "enable_execute_command" {
  description = "デバッグ用のECS Execを有効にする"
  type        = bool
  default     = false
}

# タスク定義設定
variable "task_family" {
  description = "タスク定義のファミリー名"
  type        = string
  default     = ""
}

variable "cpu" {
  description = "タスクが使用するCPUユニット数"
  type        = number
  default     = 256
  
  validation {
    condition = contains([256, 512, 1024, 2048, 4096, 8192, 16384], var.cpu)
    error_message = "CPUは次のいずれかである必要があります: 256, 512, 1024, 2048, 4096, 8192, 16384。"
  }
}

variable "memory" {
  description = "タスクが使用するメモリ量（MiB単位）"
  type        = number
  default     = 512
  
  validation {
    condition = var.memory >= 512 && var.memory <= 30720
    error_message = "メモリは512から30720 MiBの間である必要があります。"
  }
}

# コンテナ設定
variable "container_name" {
  description = "コンテナの名前"
  type        = string
  default     = ""
}

variable "container_image" {
  description = "コンテナで使用するDockerイメージ"
  type        = string
}

variable "container_port" {
  description = "コンテナがリッスンするポート"
  type        = number
  default     = 80
}

variable "container_protocol" {
  description = "コンテナが使用するプロトコル"
  type        = string
  default     = "tcp"
}

variable "environment_variables" {
  description = "コンテナの環境変数"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "secrets" {
  description = "AWS Systems Manager Parameter StoreまたはAWS Secrets Managerからの機密情報"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "container_command" {
  description = "コンテナで実行するコマンド"
  type        = list(string)
  default     = null
}

variable "container_entry_point" {
  description = "コンテナのエントリーポイント"
  type        = list(string)
  default     = null
}

# ネットワーク設定
variable "subnets" {
  description = "サービス用のサブネットIDのリスト"
  type        = list(string)
}

variable "security_groups" {
  description = "ECS Fargateタスクに適用するセキュリティグループのリスト"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "The ID of the ALB's security group to allow inbound traffic from."
  type        = string
  default     = null # ALBがない場合はnull
}

variable "database_security_group_id" {
  description = "The ID of the database security group to allow outbound traffic to."
  type        = string
  nullable    = false # 必須とする
}

variable "database_port" {
  description = "The port of the database to allow outbound traffic to (e.g., 5432 for PostgreSQL, 3306 for MySQL)."
  type        = number
  nullable    = false # 必須とする
}

variable "enable_public_internet_egress" {
  description = "Whether to allow all outbound traffic to the public internet (0.0.0.0/0). Set to false if using VPC Endpoints for all external services."
  type        = bool
  default     = true # デフォルトは許可する
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "health_check_path" {
  description = "Path for ALB health checks."
  type        = string
  default     = "/"
}

variable "enable_load_balancer" {
  description = "Whether to enable load balancer integration for the ECS service."
  type        = bool
  default     = false # デフォルトは無効にし、明示的に有効にするのが良い
}

variable "assign_public_ip" {
  description = "ENIにパブリックIPアドレスを割り当てる"
  type        = bool
  default     = false
}

# ロードバランサー設定
variable "enable_load_balancer" {
  description = "ロードバランサー統合を有効にする"
  type        = bool
  default     = false
}

variable "target_group_arn" {
  description = "ロードバランサーターゲットグループのARN"
  type        = string
  default     = ""
}

variable "load_balancer_container_name" {
  description = "ロードバランサーに関連付けるコンテナの名前"
  type        = string
  default     = ""
}

variable "load_balancer_container_port" {
  description = "ロードバランサーに関連付けるコンテナのポート"
  type        = number
  default     = 80
}

# オートスケーリング設定
variable "enable_autoscaling" {
  description = "サービスのオートスケーリングを有効にする"
  type        = bool
  default     = false
}

variable "min_capacity" {
  description = "タスクの最小数"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "タスクの最大数"
  type        = number
  default     = 10
}

variable "target_cpu_utilization" {
  description = "オートスケーリングの目標CPU使用率"
  type        = number
  default     = 70
}

variable "target_memory_utilization" {
  description = "オートスケーリングの目標メモリ使用率"
  type        = number
  default     = 80
}

# ログ設定
variable "log_group_name" {
  description = "CloudWatchロググループ名"
  type        = string
  default     = ""
}

variable "log_retention_in_days" {
  description = "ログ保持期間（日数）"
  type        = number
  default     = 30
}

variable "log_stream_prefix" {
  description = "ログストリームプレフィックス"
  type        = string
  default     = "ecs"
}

# ヘルスチェック設定
variable "health_check_grace_period_seconds" {
  description = "ヘルスチェックの猶予期間（ロードバランサー使用時）"
  type        = number
  default     = 60
}

# デプロイメント設定
variable "deployment_maximum_percent" {
  description = "デプロイメント中の実行タスク数の上限"
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "デプロイメント中の実行タスク数の下限"
  type        = number
  default     = 50
}

variable "enable_deployment_circuit_breaker" {
  description = "デプロイメントサーキットブレーカーを有効にする"
  type        = bool
  default     = true
}

variable "deployment_circuit_breaker_rollback" {
  description = "デプロイメントサーキットブレーカー失敗時のロールバックを有効にする"
  type        = bool
  default     = true
}

# サービスディスカバリー設定
variable "enable_service_discovery" {
  description = "サービスディスカバリーを有効にする"
  type        = bool
  default     = false
}

variable "service_discovery_namespace_id" {
  description = "サービスディスカバリーネームスペースID"
  type        = string
  default     = ""
}

variable "service_discovery_service_name" {
  description = "サービスディスカバリーサービス名"
  type        = string
  default     = ""
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

