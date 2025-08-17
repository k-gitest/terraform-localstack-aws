include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../modules/foundation/aurora"
}

inputs = {
  aurora_configs = {
    main_aurora_postgres = {
      engine            = "aurora-postgresql"
      engine_version    = "14.9"
      cluster_name      = "my-awesome-app-aurora-postgres-prod"
      database_name     = "maindb"
      master_username   = "postgres"
      port              = 5432

      instances = {
        writer = {
          class  = "db.r6g.large"
          public = false
        }
        reader = {
          class  = "db.r6g.large"
          public = false
        }
      }

      backup_retention     = 7
      backup_window        = "03:00-04:00"
      maintenance_window   = "sun:04:00-sun:05:00"
      storage_encrypted    = true
      deletion_protection  = true
      skip_snapshot        = false
      performance_insights = true
      monitoring_interval  = 60

      serverlessv2_scaling = {
        max_capacity = 16
        min_capacity = 2
      }
    }
  }
}
