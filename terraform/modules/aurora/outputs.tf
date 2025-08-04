# Aurora クラスターの基本情報
output "cluster_identifiers" {
  description = "Aurora クラスターの識別子マップ"
  value = {
    for cluster_key, cluster in aws_rds_cluster.aurora_cluster : 
    cluster_key => cluster.id
  }
}

output "cluster_endpoints" {
  description = "Aurora クラスターのライターエンドポイントマップ"
  value = {
    for cluster_key, cluster in aws_rds_cluster.aurora_cluster : 
    cluster_key => cluster.endpoint
  }
}

output "reader_endpoints" {
  description = "Aurora クラスターのリーダーエンドポイントマップ"
  value = {
    for cluster_key, cluster in aws_rds_cluster.aurora_cluster : 
    cluster_key => cluster.reader_endpoint
  }
}

output "cluster_ports" {
  description = "Aurora クラスターのポート番号マップ"
  value = {
    for cluster_key, cluster in aws_rds_cluster.aurora_cluster : 
    cluster_key => cluster.port
  }
}

output "cluster_database_names" {
  description = "Aurora クラスターのデータベース名マップ"
  value = {
    for cluster_key, cluster in aws_rds_cluster.aurora_cluster : 
    cluster_key => cluster.database_name
  }
}

output "cluster_master_usernames" {
  description = "Aurora クラスターのマスターユーザー名マップ"
  value = {
    for cluster_key, cluster in aws_rds_cluster.aurora_cluster : 
    cluster_key => cluster.master_username
  }
  sensitive = true
}

# Aurora インスタンス情報
output "instance_identifiers" {
  description = "Aurora インスタンスの識別子マップ"
  value = {
    for instance_key, instance in aws_rds_cluster_instance.aurora_cluster_instance : 
    instance_key => instance.id
  }
}

output "instance_endpoints" {
  description = "Aurora インスタンスのエンドポイントマップ"
  value = {
    for instance_key, instance in aws_rds_cluster_instance.aurora_cluster_instance : 
    instance_key => instance.endpoint
  }
}

output "instance_availability_zones" {
  description = "Aurora インスタンスのアベイラビリティゾーンマップ"
  value = {
    for instance_key, instance in aws_rds_cluster_instance.aurora_cluster_instance : 
    instance_key => instance.availability_zone
  }
}

# 暗号化関連
output "kms_key_id" {
  description = "Aurora 暗号化用 KMS キーの ID"
  value       = aws_kms_key.aurora_kms_key.key_id
}

output "kms_key_arn" {
  description = "Aurora 暗号化用 KMS キーの ARN"
  value       = aws_kms_key.aurora_kms_key.arn
}

output "kms_alias_name" {
  description = "Aurora 暗号化用 KMS キーのエイリアス名"
  value       = aws_kms_alias.aurora_kms_alias.name
}

# パラメータグループ
output "cluster_parameter_group_names" {
  description = "Aurora クラスター用パラメータグループ名マップ"
  value = {
    for cluster_key, pg in aws_rds_cluster_parameter_group.aurora_cluster_parameter_group : 
    cluster_key => pg.name
  }
}

output "db_parameter_group_names" {
  description = "Aurora DB 用パラメータグループ名マップ"
  value = {
    for cluster_key, pg in aws_db_parameter_group.aurora_db_parameter_group : 
    cluster_key => pg.name
  }
}

# 監視関連
output "monitoring_role_arn" {
  description = "Aurora 監視用 IAM ロールの ARN"
  value       = aws_iam_role.aurora_monitoring_role.arn
}

output "cloudwatch_log_group_names" {
  description = "Aurora 用 CloudWatch ロググループ名マップ"
  value = merge(
    {
      for cluster_key, log_group in aws_cloudwatch_log_group.aurora_log_group : 
      "${cluster_key}-postgresql" => log_group.name
    },
    {
      for log_key, log_group in aws_cloudwatch_log_group.aurora_mysql_log_groups : 
      log_key => log_group.name
    }
  )
}

# 接続情報（アプリケーション用）
output "connection_info" {
  description = "アプリケーションから接続するための情報マップ"
  value = {
    for cluster_key, cluster in aws_rds_cluster.aurora_cluster : 
    cluster_key => {
      writer_endpoint = cluster.endpoint
      reader_endpoint = cluster.reader_endpoint
      port           = cluster.port
      database_name  = cluster.database_name
      username       = cluster.master_username
      engine         = cluster.engine
      engine_version = cluster.engine_version
    }
  }
  sensitive = true
}

# 環境変数用の出力（ECS等で使用）
output "environment_variables" {
  description = "ECS等で使用する環境変数の推奨値マップ"
  value = {
    for cluster_key, cluster in aws_rds_cluster.aurora_cluster : 
    cluster_key => {
      host_writer = cluster.endpoint
      host_reader = cluster.reader_endpoint
      port        = tostring(cluster.port)
      database    = cluster.database_name
      username    = cluster.master_username
    }
  }
  sensitive = true
}

# Aurora クラスターの ARN
output "cluster_arns" {
  description = "Aurora クラスターの ARN マップ"
  value = {
    for cluster_key, cluster in aws_rds_cluster.aurora_cluster : 
    cluster_key => cluster.arn
  }
}

# Aurora インスタンスの ARN
output "instance_arns" {
  description = "Aurora インスタンスの ARN マップ"
  value = {
    for instance_key, instance in aws_rds_cluster_instance.aurora_cluster_instance : 
    instance_key => instance.arn
  }
}

# リソースのステータス情報
output "cluster_status" {
  description = "Aurora クラスターのステータス情報"
  value = {
    for cluster_key, cluster in aws_rds_cluster.aurora_cluster : 
    cluster_key => {
      status                = cluster.status
      backup_retention_period = cluster.backup_retention_period
      storage_encrypted     = cluster.storage_encrypted
      deletion_protection   = cluster.deletion_protection
      engine_version       = cluster.engine_version
      availability_zones   = cluster.availability_zones
    }
  }
}

# 詳細な接続文字列（デバッグ用）
output "connection_strings" {
  description = "データベース接続文字列の例（パスワードは含まない）"
  value = {
    for cluster_key, cluster in aws_rds_cluster.aurora_cluster : 
    cluster_key => {
      writer_connection = cluster.engine == "aurora-postgresql" ? "postgresql://${cluster.master_username}:[PASSWORD]@${cluster.endpoint}:${cluster.port}/${cluster.database_name}" : "mysql://${cluster.master_username}:[PASSWORD]@${cluster.endpoint}:${cluster.port}/${cluster.database_name}"
      reader_connection = cluster.engine == "aurora-postgresql" ? "postgresql://${cluster.master_username}:[PASSWORD]@${cluster.reader_endpoint}:${cluster.port}/${cluster.database_name}" : "mysql://${cluster.master_username}:[PASSWORD]@${cluster.reader_endpoint}:${cluster.port}/${cluster.database_name}"
    }
  }
}