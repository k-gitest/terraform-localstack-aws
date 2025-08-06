variable "project_name" {
  description = "プロジェクト名"
  type        = string
}

variable "environment" {
  description = "環境名 (e.g., local, dev, prod)"
  type        = string
}

variable "database_configs" {
  description = "Map of database configurations"
  type = map(object({
    engine                = string
    engine_version        = string
    instance_class        = string
    allocated_storage     = number
    db_name              = string
    username             = string
    password             = string
    port                 = number
    parameter_group_family = string
    skip_final_snapshot   = bool
    publicly_accessible   = bool
    custom_parameters     = map(string)
  }))
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "db_subnet_ids" {
  description = "Database subnet IDs"
  type        = list(string)
}

variable "application_security_group_id" {
  description = "アプリケーション用セキュリティグループID"
  type        = string
}

variable "db_subnet_group_name" {
  description = "Database subnet group name"
  type        = string
}

variable "database_security_group_id" {
  description = "データベース用セキュリティグループID"
  type        = string
}

variable "tags" {
  description = "リソースに適用するタグ"
  type        = map(string)
  default     = {}
}
