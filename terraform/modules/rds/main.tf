# 複数のRDSインスタンスを作成
resource "aws_db_instance" "this" {
  for_each = var.database_configs
  
  allocated_storage      = each.value.allocated_storage
  engine                = each.value.engine
  engine_version        = each.value.engine_version
  instance_class        = each.value.instance_class
  identifier            = "${var.project_name}-${var.environment}-${each.key}"
  db_name               = each.value.db_name
  username              = each.value.username
  password              = each.value.password
  port                  = each.value.port
  parameter_group_name  = aws_db_parameter_group.this[each.key].name
  skip_final_snapshot   = each.value.skip_final_snapshot
  publicly_accessible   = each.value.publicly_accessible
  vpc_security_group_ids = [var.database_security_group_id]
  db_subnet_group_name  = var.db_subnet_group_name
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-${each.key}"
      Environment = var.environment
      Project     = var.project_name
      Database    = each.key
    }
  )
}

# エンジンごとのパラメータグループを作成
resource "aws_db_parameter_group" "this" {
  for_each = var.database_configs
  
  name        = "${var.project_name}-${var.environment}-${each.key}-param-group"
  family      = each.value.parameter_group_family
  description = "${each.value.engine} parameter group for ${var.project_name} ${var.environment} ${each.key}"
  
  # カスタムパラメータを動的に設定
  dynamic "parameter" {
    for_each = each.value.custom_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-${each.key}-param-group"
      Environment = var.environment
      Project     = var.project_name
      Database    = each.key
    }
  )
}

# データベースごとのセキュリティグループ
/*
resource "aws_security_group" "db" {
  for_each = var.database_configs
  
  name        = "${var.project_name}-${var.environment}-${each.key}-sg"
  description = "Allow inbound traffic to ${each.value.engine} DB (${each.key})"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port       = each.value.port
    to_port         = each.value.port
    protocol        = "tcp"
    security_groups = [var.database_security_group_id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-${each.key}-sg"
      Environment = var.environment
      Project     = var.project_name
      Database    = each.key
    }
  )
}
*/

# networkモジュールから渡されるDB用SGに対してルールを追加
/*
resource "aws_security_group_rule" "rds_ingress_from_app" {
  for_each = var.database_configs

  type                     = "ingress"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = "tcp"
  security_group_id        = var.database_security_group_id
  source_security_group_id = var.application_security_group_id
  description              = "Allow access to ${each.key} from application servers"
}
*/

# RDSからの外部通信を許可（必要であれば）
/*
resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # All protocols
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = var.database_security_group_id 
  description       = "Allow all outbound traffic for RDS"
}
*/