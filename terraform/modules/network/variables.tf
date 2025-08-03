variable "project_name" {
  description = "プロジェクト名"
  type        = string
}

variable "environment" {
  description = "デプロイ環境 (e.g., dev, prod)"
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPCのCIDRブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "パブリックサブネットのCIDRブロックリスト"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "プライベートサブネットのCIDRブロックリスト (必要であれば)"
  type        = list(string)
  default     = []
}

variable "ingress_rules" {
  description = "Fargateセキュリティグループのイングレスルール"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    security_groups = optional(list(string), [])
  }))
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "egress_rules" {
  description = "Fargateセキュリティグループのエグレスルール"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    security_groups = optional(list(string), [])
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "tags" {
  description = "リソースに適用するタグ"
  type        = map(string)
  default     = {}
}

variable "dev_ssh_cidr" {
  description = "開発環境でのSSHアクセスを許可するCIDRブロック"
  type        = string
  default     = "10.0.0.0/8" # デフォルトは内部ネットワークのみ
}

variable "enable_dev_ssh" {
  description = "開発環境でのSSHアクセスを有効にするかどうか"
  type        = bool
  default     = false
}

variable "database_engines" {
  description = "使用するデータベースエンジンのリスト"
  type        = list(string)
  default     = ["postgres", "mysql"]
  validation {
    condition = alltrue([
      for engine in var.database_engines : contains(["postgres", "mysql", "aurora-postgresql", "aurora-mysql"], engine)
    ])
    error_message = "サポートされているエンジンは postgres, mysql, aurora-postgresql, aurora-mysql です。"
  }
}

# アプリケーションポートの設定
variable "application_port" {
  description = "アプリケーションがリッスンするポート"
  type        = number
  default     = 8080
}

# データベースポートの設定
variable "database_ports" {
  description = "データベースエンジンごとのポート設定"
  type = object({
    postgres = number
    mysql    = number
  })
  default = {
    postgres = 5432
    mysql    = 3306
  }
}