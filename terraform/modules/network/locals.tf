locals {
  # データベースエンジンとポートのマッピング
  database_port_mapping = {
    postgres           = var.database_ports.postgres
    mysql             = var.database_ports.mysql
    aurora-postgresql = var.database_ports.postgres
    aurora-mysql      = var.database_ports.mysql
  }

  # 使用するデータベースポートのリスト（重複を除去）
  database_ports_unique = distinct([
    for engine in var.database_engines : local.database_port_mapping[engine]
  ])

  # 共通タグ
  common_security_group_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })
}