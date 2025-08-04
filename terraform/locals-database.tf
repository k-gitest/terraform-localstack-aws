# データベース関連のlocals

locals {
  # RDS設定
  rds_configs = {
    main_postgres = {
      engine         = "postgres"
      engine_version = "14.7"
      instance_class = var.environment == "prod" ? "db.t3.medium" : "db.t3.small"
      storage        = var.environment == "prod" ? 100 : 20
      db_name        = "maindb"
      username       = "appuser"
      port          = 5432
      family        = "postgres14"
      skip_snapshot = var.environment != "prod"
      publicly_accessible = false
      backup_retention = var.environment == "prod" ? 7 : 1
      backup_window = "03:00-04:00"
      maintenance_window = "sun:04:00-sun:05:00"
    }
    
    analytics_mysql = {
      engine         = "mysql"
      engine_version = "8.0.35"
      instance_class = "db.t3.micro"
      storage        = 20
      db_name        = "analytics"
      username       = "analytics_user"
      port          = 3306
      family        = "mysql8.0"
      skip_snapshot = true
      publicly_accessible = false
      backup_retention = 5
      backup_window = "03:00-04:00"
      maintenance_window = "sun:04:00-sun:05:00"
    }
  }

  # Aurora設定
  aurora_configs = {
    main_aurora_postgres = {
      engine            = "aurora-postgresql"
      engine_version    = "14.9"
      cluster_name      = "${var.project_name}-aurora-postgres-${var.environment}"
      database_name     = "maindb"
      master_username   = "postgres"
      port             = 5432
      
      instances = {
        writer = {
          class = var.environment == "prod" ? "db.r6g.large" : "db.r6g.medium"
          public = false
        }
        reader = var.environment == "prod" ? {
          class = "db.r6g.large"
          public = false
        } : null
      }
      
      backup_retention = var.environment == "prod" ? 7 : 3
      backup_window = "03:00-04:00"
      maintenance_window = "sun:04:00-sun:05:00"
      storage_encrypted = true
      deletion_protection = var.environment == "prod"
      skip_snapshot = var.environment != "prod"
      performance_insights = var.environment == "prod"
      monitoring_interval = var.environment == "prod" ? 60 : 0
      
      serverlessv2_scaling = var.environment == "prod" ? {
        max_capacity = 16
        min_capacity = 2
      } : {
        max_capacity = 4
        min_capacity = 0.5
      }
    }
  }
}