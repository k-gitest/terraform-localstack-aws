include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/foundation/aurora"
}

inputs = {
  aurora_configs = {
    main_aurora_postgres = {
      engine               = "aurora-postgresql"
      engine_version       = "14.9"
      cluster_name         = "${local.project_name}-aurora-postgres-${local.environment}"
      database_name        = "maindb"
      master_username      = "postgres"
      port                 = 5432
      instances = {
        writer = {
          class  = "db.r6g.medium"
          public = false
        }
      }
      backup_retention     = 3
      backup_window        = "03:00-04:00"
      maintenance_window   = "sun:04:00-sun:05:00"
      storage_encrypted    = true
      deletion_protection  = false
      skip_snapshot        = true
      performance_insights = false
      monitoring_interval  = 0
      serverlessv2_scaling = {
        max_capacity = 4
        min_capacity = 0.5
      }
    }
  }
}
