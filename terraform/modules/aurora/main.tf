# Aurora用セキュリティグループ
/*
resource "aws_security_group" "aurora_security_group" {
  name_prefix = "${var.project_name}-aurora-sg-${var.environment}"
  vpc_id      = var.vpc_id
  description = "Security group for Aurora clusters"

  tags = merge(var.tags, {
    Name = "${var.project_name}-aurora-security-group-${var.environment}"
    Type = "Aurora"
  })
}
*/

# ECSからAuroraへのアクセスを許可
/*
resource "aws_security_group_rule" "aurora_ingress_from_ecs" {
  for_each = {
    for cluster_name, config in var.aurora_configs : cluster_name => config.port
  }

  type                     = "ingress"
  from_port                = each.value
  to_port                  = each.value
  protocol                 = "tcp"
  security_group_id        = var.database_security_group_id
  source_security_group_id = var.application_security_group_id
  description              = "Allow access to port ${each.value} from ECS for ${each.key} cluster"
}
*/

# Auroraからの外部通信を許可（アップデートなどのため）
/*
resource "aws_security_group_rule" "aurora_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535 # or specific ports if needed
  protocol          = "tcp" # or "-1" for all protocols
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = var.database_security_group_id
  description       = "Allow all outbound traffic for Aurora"
}
*/

# Auroraクラスター用パラメータグループ
resource "aws_rds_cluster_parameter_group" "aurora_cluster_parameter_group" {
  for_each = var.aurora_configs

  family = each.value.cluster_parameter_group_family
  name   = "${var.project_name}-${each.key}-cluster-pg-${var.environment}"

  dynamic "parameter" {
    for_each = each.value.custom_cluster_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${each.key}-cluster-parameter-group-${var.environment}"
    ClusterType = each.key
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Aurora DB用パラメータグループ
resource "aws_db_parameter_group" "aurora_db_parameter_group" {
  for_each = var.aurora_configs

  family = each.value.db_parameter_group_family
  name   = "${var.project_name}-${each.key}-db-pg-${var.environment}"

  dynamic "parameter" {
    for_each = each.value.custom_db_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${each.key}-db-parameter-group-${var.environment}"
    ClusterType = each.key
  })

  lifecycle {
    create_before_destroy = true
  }
}

# KMSキー（Aurora暗号化用）
resource "aws_kms_key" "aurora_kms_key" {
  description             = "KMS key for Aurora encryption in ${var.environment}"
  deletion_window_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.project_name}-aurora-kms-key-${var.environment}"
    Type = "Aurora"
  })
}

resource "aws_kms_alias" "aurora_kms_alias" {
  name          = "alias/${var.project_name}-aurora-${var.environment}"
  target_key_id = aws_kms_key.aurora_kms_key.key_id
}

# Auroraクラスター
resource "aws_rds_cluster" "aurora_cluster" {
  for_each = var.aurora_configs

  cluster_identifier     = each.value.cluster_identifier
  engine                = each.value.engine
  engine_version        = each.value.engine_version
  database_name         = each.value.database_name
  master_username       = each.value.master_username
  master_password       = each.value.master_password
  port                  = each.value.port

  # ネットワーク設定
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.database_security_group_id]

  # バックアップ設定
  backup_retention_period   = each.value.backup_retention_period
  preferred_backup_window   = each.value.preferred_backup_window
  preferred_maintenance_window = each.value.preferred_maintenance_window
  copy_tags_to_snapshot     = true

  # セキュリティ設定
  storage_encrypted       = each.value.storage_encrypted
  kms_key_id             = each.value.storage_encrypted ? aws_kms_key.aurora_kms_key.arn : null
  deletion_protection    = each.value.deletion_protection
  skip_final_snapshot    = each.value.skip_final_snapshot
  final_snapshot_identifier = each.value.final_snapshot_identifier

  # パフォーマンス設定
  enabled_cloudwatch_logs_exports = each.value.engine == "aurora-postgresql" ? ["postgresql"] : ["audit", "error", "general", "slowquery"]
  
  # パラメータグループ
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_cluster_parameter_group[each.key].name

  # サーバーレスv2設定（設定されている場合）
  dynamic "serverlessv2_scaling_configuration" {
    for_each = can(each.value.serverlessv2_scaling_configuration) ? [each.value.serverlessv2_scaling_configuration] : []
    content {
      max_capacity = serverlessv2_scaling_configuration.value.max_capacity
      min_capacity = serverlessv2_scaling_configuration.value.min_capacity
    }
  }

  # その他の設定
  apply_immediately               = false
  #auto_minor_version_upgrade     = each.value.auto_minor_version_upgrade
  backtrack_window              = each.value.engine == "aurora-mysql" ? 72 : 0
  enable_http_endpoint          = false

  tags = merge(var.tags, {
    Name        = each.value.cluster_identifier
    ClusterType = each.key
    Engine      = each.value.engine
  })

  depends_on = [
    aws_rds_cluster_parameter_group.aurora_cluster_parameter_group
  ]

  lifecycle {
    ignore_changes = [
      master_password,
      engine_version
    ]
  }
}

# Auroraクラスターインスタンス
resource "aws_rds_cluster_instance" "aurora_cluster_instance" {
  for_each = merge([
    for cluster_key, cluster_config in var.aurora_configs : {
      for instance_key, instance_config in cluster_config.instances :
      "${cluster_key}-${instance_key}" => {
        cluster_identifier   = cluster_key
        cluster_config      = cluster_config
        instance_key        = instance_key
        instance_config     = instance_config
      }
    }
  ]...)

  identifier                = "${each.value.cluster_config.cluster_identifier}-${each.value.instance_key}"
  cluster_identifier        = aws_rds_cluster.aurora_cluster[each.value.cluster_identifier].id
  instance_class           = each.value.instance_config.instance_class
  engine                   = each.value.cluster_config.engine
  engine_version           = each.value.cluster_config.engine_version
  publicly_accessible     = each.value.instance_config.publicly_accessible

  # パフォーマンス設定
  performance_insights_enabled = each.value.cluster_config.performance_insights_enabled
  performance_insights_kms_key_id = each.value.cluster_config.performance_insights_enabled ? aws_kms_key.aurora_kms_key.arn : null
  performance_insights_retention_period = each.value.cluster_config.performance_insights_enabled ? 7 : null
  monitoring_interval      = each.value.cluster_config.monitoring_interval
  monitoring_role_arn     = each.value.cluster_config.monitoring_interval > 0 ? aws_iam_role.aurora_monitoring_role.arn : null

  # パラメータグループ
  db_parameter_group_name = aws_db_parameter_group.aurora_db_parameter_group[each.value.cluster_identifier].name

  # その他の設定
  auto_minor_version_upgrade = each.value.cluster_config.auto_minor_version_upgrade
  copy_tags_to_snapshot     = true

  tags = merge(var.tags, {
    Name         = "${each.value.cluster_config.cluster_identifier}-${each.value.instance_key}"
    ClusterType  = each.value.cluster_identifier
    InstanceType = each.value.instance_key
    Engine       = each.value.cluster_config.engine
  })

  depends_on = [
    aws_rds_cluster.aurora_cluster,
    aws_db_parameter_group.aurora_db_parameter_group
  ]
}

# Aurora監視用IAMロール
resource "aws_iam_role" "aurora_monitoring_role" {
  name = "${var.project_name}-aurora-monitoring-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-aurora-monitoring-role-${var.environment}"
    Type = "Aurora"
  })
}

resource "aws_iam_role_policy_attachment" "aurora_monitoring_role_policy" {
  role       = aws_iam_role.aurora_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# CloudWatch Log Group（Aurora用）
resource "aws_cloudwatch_log_group" "aurora_log_group" {
  for_each = {
    for cluster_key, cluster_config in var.aurora_configs : cluster_key => cluster_config
    if cluster_config.engine == "aurora-postgresql"
  }

  name              = "/aws/rds/cluster/${each.value.cluster_identifier}/postgresql"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name        = "${each.value.cluster_identifier}-postgresql-logs"
    ClusterType = each.key
  })
}

resource "aws_cloudwatch_log_group" "aurora_mysql_log_groups" {
  for_each = merge([
    for cluster_key, cluster_config in var.aurora_configs : 
    cluster_config.engine == "aurora-mysql" ? {
      for log_type in ["audit", "error", "general", "slowquery"] :
      "${cluster_key}-${log_type}" => {
        cluster_identifier = cluster_config.cluster_identifier
        log_type          = log_type
        cluster_key       = cluster_key
      }
    } : {}
  ]...)

  name              = "/aws/rds/cluster/${each.value.cluster_identifier}/${each.value.log_type}"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name        = "${each.value.cluster_identifier}-${each.value.log_type}-logs"
    ClusterType = each.value.cluster_key
  })
}